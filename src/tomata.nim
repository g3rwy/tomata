import nimraylib_now
const
  BUFFER_SCALE = 3
  WIDTH = 600
  HEIGHT = 600
  STATES_COUNT = 2

type
  cell_grid = array[ (HEIGHT.toFloat / BUFFER_SCALE.toFloat).toInt , array[ (WIDTH.toFloat / BUFFER_SCALE).toInt , uint8]]

var
  Window_size = Vector2(x:WIDTH,y:HEIGHT)
  buffer : cell_grid
  states_colors : array[STATES_COUNT, Color]

setConfigFlags(WINDOW_RESIZABLE)
initWindow(cint(Window_size.x),cint(Window_size.y), "Game of Life")
setTargetFPS(60)

states_colors = [
  Red, # DEAD
  Green  # ALIVE
]

proc randomizeGrid(grid : var cell_grid) = 
  for c in grid.mitems:
    for states in c.mitems:
      states = uint8(getRandomValue(0,1))

proc countN(grid : var cell_grid, x: int, y: int) : int = # Count Neigbhours in donut maner
  var sum = 0;
  for i in -1 .. 1:
    for j in -1 .. 1:
      let col = (x + i + buffer.len) mod buffer.len
      let row = (y + j + buffer[0].len) mod buffer[0].len
      sum += cast[int](grid[col][row])
  
  sum -= cast[int](grid[x][y])
  return sum

buffer.randomizeGrid

when isMainModule:
  while not windowShouldClose():
    var next : cell_grid
    if isWindowResized(): Window_size = (x: getScreenWidth().toFloat, y: getScreenHeight().toFloat)

    beginDrawing()
    clearBackground Raywhite

    for i ,c in buffer.pairs:
      for j ,states in c.pairs:
        #let x = (BUFFER_SCALE * j)
        #let y = (BUFFER_SCALE * i)
        drawRectangle((BUFFER_SCALE * j) ,(BUFFER_SCALE * i) , BUFFER_SCALE , BUFFER_SCALE , states_colors[states])



    for i ,c in buffer.pairs:
      for j ,states in c.pairs:
        let n = buffer.countN(i,j)
        #let state = buffer[i][j]

        # RULES 
        if buffer[i][j] == 0 and n == 3:
          next[i][j] = 1
        elif buffer[i][j] == 1 and (n < 2 or n > 3):
          next[i][j] = 0
        else:
          next[i][j] = buffer[i][j]

    buffer = next
    if isKeyReleased(Space):
      buffer.randomizeGrid
    drawFPS(10,10)
    endDrawing()

closeWindow()