import nimraylib_now
const
  BUFFER_SCALE = 2
  WIDTH = 1280
  HEIGHT = 800

type
  grid = array[ (HEIGHT.toFloat / BUFFER_SCALE.toFloat).toInt , array[ (WIDTH.toFloat / BUFFER_SCALE).toInt , bool]]

var
  steps : uint = 0
  Window_size = Vector2(x:WIDTH,y:HEIGHT)
  terrarium : grid
  states_colors : array[2, Color]
  play : bool = true

states_colors =[
    White, # Empty
    Black # Ant been there
]

var Ant : tuple[x: int, y: int, dir: Vector2] = (x: int(terrarium.len / 2), y: int(terrarium[0].len / 2), dir: Vector2(x: 0.0, y: -1.0))

setConfigFlags(WINDOW_RESIZABLE)
initWindow(cint(Window_size.x),cint(Window_size.y), "Antz")
setTargetFPS(144)

while not windowShouldClose():
    if isWindowResized(): Window_size = (x: getScreenWidth().toFloat, y: getScreenHeight().toFloat)

    beginDrawing()
    clearBackground Raywhite
    for i ,c in terrarium.pairs:
      for j ,place in c.pairs:
        #let x = (BUFFER_SCALE * j)
        #let y = (BUFFER_SCALE * i)
        drawRectangle((BUFFER_SCALE * j) ,(BUFFER_SCALE * i) , BUFFER_SCALE , BUFFER_SCALE , states_colors[place.ord])
    
    drawText("Steps: " & $steps,10,10,15,Black)
    drawRectangleLines(cint(BUFFER_SCALE * Ant.y),cint(BUFFER_SCALE * Ant.x), BUFFER_SCALE, BUFFER_SCALE, Red) # Ant
    endDrawing()

    if play:
        for _ in 1..10: # how much steps does the ant needs to do (its pretty boring so i speed it up) CAN BE CHANGED
            if terrarium[Ant.x][Ant.y]: # if black = if true, rotate left
                Ant.dir = Ant.dir.rotate(-90)
            else: # else white then rotate right
                Ant.dir = Ant.dir.rotate(90)
            
            terrarium[Ant.x][Ant.y] = not terrarium[Ant.x][Ant.y] # flip the color of the cell

            Ant.x += int(Ant.dir.x) 
            Ant.y += int(Ant.dir.y)

            if Ant.x == terrarium.len:
                Ant.x = 0
            elif Ant.x < 0:
                Ant.x = terrarium.len - 1

            if Ant.y == terrarium[0].len:
                Ant.y = 0
            elif Ant.y < 0:
                Ant.y = terrarium[0].len - 1

            inc steps
    
    if isKeyReleased(Space):
      play = not play

closeWindow()