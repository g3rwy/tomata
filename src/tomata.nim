import nimraylib_now
const
  BUFFER_SCALE = 1
  WIDTH = 600
  HEIGHT = 600

type
  State = tuple
    idx : uint8
    color : Color

  cell_grid = array[ (HEIGHT.toFloat / BUFFER_SCALE.toFloat).toInt , array[ (WIDTH.toFloat / BUFFER_SCALE).toInt , State]]
var
  Window_size = Vector2(x:WIDTH,y:HEIGHT)
  
  dead : State = (0'u8, Lightgray)
  alive : State = (1'u8, Black)
  
  buffer : cell_grid

setConfigFlags(WINDOW_RESIZABLE)
initWindow(cint(Window_size.x),cint(Window_size.y), "Game of Life")
setTargetFPS(60)

proc randomizeGrid(grid : var cell_grid) = 
  for c in grid.mitems:
    for states in c.mitems:
      states = if getRandomValue(0,1) == 0: dead else: alive

proc countN(grid : var cell_grid, x: int, y: int) : int = # Count Neigbhours in donut maner
  var sum = 0;
  for i in -1 .. 1:
    for j in -1 .. 1:
      sum += cast[int](grid[i + x][j + y].idx)
  
  sum -= cast[int](grid[x][y].idx)
  return sum

buffer.randomizeGrid

when isMainModule:
  while not windowShouldClose():
    var next : cell_grid
    echo "------------------------------------"
    if isWindowResized(): Window_size = (x: getScreenWidth().toFloat, y: getScreenHeight().toFloat)

    beginDrawing()
    clearBackground Raywhite

    for i ,c in buffer.pairs:
      for j ,states in c.pairs:
        let x = (BUFFER_SCALE * j)
        let y = (BUFFER_SCALE * i)
        drawRectangle(x , y , BUFFER_SCALE , BUFFER_SCALE , states.color)



    for i ,c in buffer.pairs:
      for j ,states in c.pairs:
        if i == 0 or i == (c.len - 1) or j == 0 or j == (buffer.len - 1):
          next[i][j] = buffer[i][j]
        else:

          let n = buffer.countN(i,j)
          let state = buffer[i][j].idx

          # RULES 
          if state == 0 and n == 3:
            next[i][j] = alive
          elif state == 1 and (n < 2 or n > 3):
            next[i][j] = dead
          else:
            next[i][j] = buffer[i][j]

    buffer = next
    if isKeyReleased(Space):
      buffer.randomizeGrid
    endDrawing()

closeWindow()