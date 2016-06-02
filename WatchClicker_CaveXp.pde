final static int AUTOMATA_ITERATIONS_NB = 2;
final static float INITIAL_WALLS_RATIO = 0.51;
final static int WALL_DEATH_LIMIT = 3;
final static int WALL_BIRTH_LIMIT = 4;
final static float PATH_SQUARE_DISTANCE_LIMIT = 9;

final static int CELL_W = 3;

final static byte CELL_EMPTY = 0;
final static byte CELL_WALL = 1;
final static byte CELL_PATH = 2;

byte[][] mapTopLeft, mapTop, mapTopRight,
         mapLeft,  mapCenter,   mapRight,
         mapBotLeft, mapBot, mapBotRight;

ArrayList<PVector> pathTopLeft, pathTop, pathTopRight,
                   pathLeft,  pathCenter,   pathRight,
                   pathBotLeft, pathBot, pathBotRight;
                   
ArrayList<PVector>[] paths;
byte[][][] map;

int mapW, mapH, mapWH, mapScreenW, mapScreenH;


int lastMousePressedX, lastMousePressedY, viewShiftX = 0, viewShiftY = 0; // tmp


void setup()
{
  size(320, 320);
  noStroke();
  mapW = width / CELL_W;
  mapH = height / CELL_W;
  mapWH = mapW * mapH;
  mapScreenW = CELL_W * mapW;
  mapScreenH = CELL_W * mapH;
  
  paths = (ArrayList<PVector>[])new ArrayList[9];
  
  for (int i = 0; i < 9; ++i)
    paths[i] = new ArrayList<PVector>();

  initPaths(new IntList(0,1,2,3,4,5,6,7,8,9), 4, new PVector((int)(mapW * 0.5), (int)(mapH * 0.5), 0));
  
  map = new byte[9][mapH][mapW];
  
  for (int i = 0; i < 9; ++i)
    map[i] = initCells(i);
}


void draw ()
{
  background(0);
  pushMatrix();
  translate(-mapScreenW, -mapScreenH);
  
  for (int i = 0; i < map.length; ++i)
  {
    int mapX = (i % 3) * mapScreenW;
    int mapY = (i / 3) * mapScreenH;
    
    for (int r = 0; r < mapH; ++r)
    {
      int y = mapY + r * CELL_W + viewShiftY;
      
      for (int c = 0; c < mapW; ++c)
      {
        int x = mapX + c * CELL_W + viewShiftX;
        
        switch (map[i][r][c])
        {
          case CELL_EMPTY:
            break;
          case CELL_WALL:
            fill(140, 128, 120);
            rect(x, y, CELL_W, CELL_W);
            break;
          case CELL_PATH:
            fill(0, 255, 0);
            rect(x, y, CELL_W, CELL_W);
            break;
        }
      }
    }
  }
  popMatrix();
}


void initPaths (IntList pathsToUpdateIdx, int pathIdx, PVector lastPathCell)
{
  if (!pathsToUpdateIdx.hasValue(pathIdx)) // forbidden
  {
    initPaths(pathsToUpdateIdx, pathIdx + 1, new PVector(lastPathCell.x, lastPathCell.y, lastPathCell.z + PI));
    return;
  }
  
  ArrayList<PVector> path = paths[pathIdx];
  
  //path.clear(); // NO!
  
  float pathAngle = lastPathCell.z;
  int pathX = lastPathCell.x < 0 ? mapW - 1 : lastPathCell.x >= mapW ? 0 : (int)lastPathCell.x;
  int pathY = lastPathCell.y < 0 ? mapH - 1 : lastPathCell.y >= mapH ? 0 : (int)lastPathCell.y;
  
  do
  {
    path.add(new PVector(pathX, pathY, pathAngle));

    pathAngle += random(PI * 0.4) - PI * 0.2;
    pathX += round(cos(pathAngle));
    pathY -= round(sin(pathAngle));
  }
  while (pathX >= 0 && pathX < mapW && pathY >= 0 && pathY < mapH);
  
  // recursion:
  
  PVector pathCell = path.get(path.size() - 1);
  boolean gotoTop = pathY < 0;
  boolean gotoBot = pathY >= mapH;
  
  if (pathX < 0) // goto left
  {
    if (gotoTop) // top - left
    {
      if (pathIdx == 4 || pathIdx == 5 || pathIdx == 7 || pathIdx == 8)
        initPaths(pathsToUpdateIdx, pathIdx - 4, new PVector(mapW - 1, mapH - 1, pathCell.z));
    }
    else if (gotoBot) // bot - left
    {
      if (pathIdx == 1 || pathIdx == 2 || pathIdx == 4 || pathIdx == 5)
        initPaths(pathsToUpdateIdx, pathIdx + 2, new PVector(mapW - 1, 0, pathCell.z));
    }
    else if (pathIdx != 0 && pathIdx != 3 && pathIdx != 6) // left
    {
      initPaths(pathsToUpdateIdx, pathIdx - 1, new PVector(mapW - 1, pathCell.y, pathCell.z));
    }
  }
  else if (pathX >= mapW) // goto right
  {
    if (gotoTop) // top - right
    {
      if (pathIdx == 3 || pathIdx == 4 || pathIdx == 6 || pathIdx == 7)
        initPaths(pathsToUpdateIdx, pathIdx - 2, new PVector(0, mapH - 1, pathCell.z));
    }
    else if (gotoBot) // bot - right
    {
      if (pathIdx == 0 || pathIdx == 1 || pathIdx == 3 || pathIdx == 4)
        initPaths(pathsToUpdateIdx, pathIdx + 4, new PVector(0, 0, pathCell.z));
    }
    else if (pathIdx != 2 && pathIdx != 5 && pathIdx != 8) // right
    {
      initPaths(pathsToUpdateIdx, pathIdx + 1, new PVector(0, pathCell.y, pathCell.z));
    }
  }
  else if (gotoTop)
  {
    if (pathIdx > 2) // top
      initPaths(pathsToUpdateIdx, pathIdx - 3, new PVector(pathCell.x, mapH - 1, pathCell.z));
  }
  else if (gotoBot)
  {
    if (pathIdx < 6) // bot
      initPaths(pathsToUpdateIdx, pathIdx + 3, new PVector(pathCell.x, 0, pathCell.z));
  }
}


byte[][] initCells (int idx)
{
  byte[][] cells = new byte[mapH][mapW];
 
  // step 1: set path cells
  for (int i = paths[idx].size() - 1; i >= 0; --i)
  {
    PVector pathCell = paths[idx].get(i);
    cells[(int)pathCell.y][(int)pathCell.x] = CELL_PATH;
  }

  // step 2: init random walls
  for (int i = (int)(mapWH * INITIAL_WALLS_RATIO); i >= 0; --i)
  {
    int rnd = (int)random(mapWH);
    int r = rnd / mapW;
    int c = rnd % mapW;
    
    if (cells[r][c] != CELL_PATH)
      cells[r][c] = CELL_WALL;
  }

  // step3: cellular automation
  for (int i = 0; i < AUTOMATA_ITERATIONS_NB; ++i)
    cells = caveGenerationStep(cells, paths[idx]);
    
  return cells;
}


byte[][] caveGenerationStep (byte[][] oldCells, ArrayList<PVector> path)
{
  byte[][] cells = new byte[mapH][mapW];
  
  for (int r = 0; r < mapH; ++r)
  {
    for (int c = 0; c < mapW; ++c)
    {
      if (oldCells[r][c] == CELL_PATH)
      {
        cells[r][c] = CELL_PATH;
        continue;
      }
      
      int wallsCount = countWallsAround(oldCells, c, r);
      
      if (path != null && wallsCount == -1 || isTooCloseToPath(path, c, r)) // the path is too close
      {
        cells[r][c] = CELL_EMPTY;
        continue;
      }

      if (oldCells[r][c] == CELL_WALL)
      {
        cells[r][c] = wallsCount < WALL_DEATH_LIMIT ? CELL_EMPTY : CELL_WALL;
      }
      else
      {
        cells[r][c] = wallsCount > WALL_BIRTH_LIMIT ? CELL_WALL : CELL_EMPTY;
      }
    }
  }
  
  return cells;
}


int countWallsAround (byte[][] cells, int col, int row)
{
  int wallsCount = 0;
  boolean topCellExists = row > 0;
  boolean botCellExists = row < mapH - 1;
  int leftI = col - 1;
  int rightI = col + 1;
  int topI = row - 1;
  int botI = row + 1;
  
  if (col > 0) // left cell exists
  {
    if (topCellExists) // top - left
    {
      if (cells[topI][leftI] == CELL_PATH)
        return -1;
      else if (cells[topI][leftI] == CELL_WALL)
        ++wallsCount;
    }
    
    if (botCellExists) // bot - left
    {
      if (cells[botI][leftI] == CELL_PATH)
        return -1;
      else if (cells[botI][leftI] == CELL_WALL)
        ++wallsCount;
    }
    
    if (cells[row][leftI] == CELL_PATH) // left
      return -1;
    else if (cells[row][leftI] == CELL_WALL)
      ++wallsCount;
  }
  
  if (col < mapW - 1) // right cell exists
  {
    if (topCellExists) // top - right
    {
      if (cells[topI][rightI] == CELL_PATH)
        return -1;
      else if (cells[topI][rightI] == CELL_WALL)
        ++wallsCount;
    }
    
    if (botCellExists) // bot - right
    {
      if (cells[botI][rightI] == CELL_PATH)
        return -1;
      else if (cells[botI][rightI] == CELL_WALL)
        ++wallsCount;
    }
    
    if (cells[row][rightI] == CELL_PATH) // right
      return -1;
    else if (cells[row][rightI] == CELL_WALL)
      ++wallsCount;
  }
  
  if (topCellExists) // top
  {
    if (cells[topI][col] == CELL_PATH)
      return -1;
    else if (cells[topI][col] == CELL_WALL)
      ++wallsCount;
  }
  
  if (botCellExists) // bot
  {
    if (cells[botI][col] == CELL_PATH)
      return -1;
    else if (cells[botI][col] == CELL_WALL)
      ++wallsCount;
  }

  return wallsCount;
}


boolean isTooCloseToPath (ArrayList<PVector> path, int col, int row)
{
  for (int i = path.size() - 1; i >= 0; --i)
  {
    PVector pathCell = path.get(i);
    if (sqDist(pathCell.x, pathCell.y, col, row) < PATH_SQUARE_DISTANCE_LIMIT)
      return true;
  }
  return false; 
}


float sqDist (float x1, float y1, float x2, float y2)
{
  float dx = x2 - x1;
  float dy = y2 - y1;
  return dx * dx + dy * dy;
}


void mousePressed ()
{
  lastMousePressedX = mouseX;
  lastMousePressedY = mouseY;
}


void mouseDragged () 
{
  viewShiftX += mouseX - lastMousePressedX;
  viewShiftY += mouseY - lastMousePressedY;
  lastMousePressedX = mouseX;
  lastMousePressedY = mouseY;
}