import nimraylib_now
import strformat

const
  BUFFER_SCALE* = 3
  WIDTH* = 600
  HEIGHT* = 600
  STATES_COUNT = 2

type
  cell_grid = array[ (HEIGHT.toFloat / BUFFER_SCALE.toFloat).toInt , array[ (WIDTH.toFloat / BUFFER_SCALE).toInt , uint8]]

var
  steps : uint = 0
  Window_size = Vector2(x:WIDTH,y:HEIGHT)
  buffer : cell_grid
  states_colors : array[STATES_COUNT, Color]
  play : bool = true
  tick_speed : float32 = 0.0 # default value is Delta
  counter : float32 = 0.0 # used to count when the tick should update

  n : cell_grid
  base = cast[ptr cell_grid](addr buffer)
  next_step = cast[ptr cell_grid](addr n)

states_colors = [ # COLORS
  Red, # DEAD
  Green  # ALIVE
]


setConfigFlags(WINDOW_RESIZABLE)
initWindow(cint(Window_size.x) + 300,cint(Window_size.y), "Game of Life")
setTargetFPS(144)

proc randomizeGrid(grid : var cell_grid) = 
  for c in grid.mitems:
    for states in c.mitems:
      states = uint8(getRandomValue(0,1))

proc countN(grid : var cell_grid, x: int, y: int) : int = # Count Neigbhours in donut maner
  result = 0
  for i in -1 .. 1:
    for j in -1 .. 1:
      let col = (x + i + base[].len) mod base[].len
      let row = (y + j + base[0].len) mod base[0].len
      result += cast[int](grid[col][row])
  
  result -= cast[int](grid[x][y]) # dirty way of removing the center of donut (now a donut, before that just a circle)

base[].randomizeGrid

when isMainModule:
  tick_speed = getFrameTime()
  while not windowShouldClose():
    counter += getFrameTime()
    #if isWindowResized(): Window_size = (x: getScreenWidth().toFloat, y: getScreenHeight().toFloat)

    beginDrawing()
    clearBackground Raywhite
    for i ,c in base[].pairs:
      for j ,states in c.pairs:
        #let x = (BUFFER_SCALE * j)
        #let y = (BUFFER_SCALE * i)
        drawRectangle((BUFFER_SCALE * j) ,(BUFFER_SCALE * i) , BUFFER_SCALE , BUFFER_SCALE , states_colors[states])

    if play:
      if counter >= tick_speed:
        for i ,c in base[].pairs:
          for j ,states in c.pairs:
            let n = base[].countN(i,j)

            # RULES 
            if base[i][j] == 0 and n == 3:
              next_step[i][j] = 1
            elif base[i][j] == 1 and (n < 2 or n > 3):
              next_step[i][j] = 0
            else:
              next_step[i][j] = base[i][j]

        swap(base,next_step)
        inc steps
        counter -= tick_speed

    if isKeyReleased(Space):
      play = not play
    if isKeyReleased(Enter):
      base[].randomizeGrid

    if tick_speed <= getFrameTime():
      drawText("Update every frame",WIDTH + 15, 30, 18,Black)
    else:
      drawText(fmt" {(1'f32 / tick_speed):3.2f} updates per second",WIDTH + 15, 30, 18,Black) # it formats tickspeed as float nicely

    drawText("Steps: " & $steps,10,10,15,Black)
    endDrawing()
    tickspeed = slider((float64(WIDTH + 10), 50'f64, 230'f64, 10'f64),"","",tick_speed,0.0,2.0)

closeWindow()