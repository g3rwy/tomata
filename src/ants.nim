import nimraylib_now

var
  BUFFER_SCALE = 2
  WIDTH = 1000
  HEIGHT = 600

type
  #grid = array[ (HEIGHT.toFloat / BUFFER_SCALE.toFloat).toInt , array[ (WIDTH.toFloat / BUFFER_SCALE).toInt , bool]]
  grid = array[ 300, array[ 500, bool]] #! Problem with scaling

var
  steps : uint = 0
  terrarium* : grid
  cell_colors* : array[2, Color]
  play* : bool = true
  tick_speed* : float32 = 0.0 
  counter : float32 = 0.0
  steps_per_tick* : uint = 10 

cell_colors =[
    White, # Empty
    Black # Ant been there
]

var Ant* : tuple[x: int, y: int, dir: Vector2] = (x: int(terrarium.len / 2), y: int(terrarium[0].len / 2), dir: Vector2(x: 0.0, y: -1.0)) # Ant having coords and direction its heading

#setConfigFlags(WINDOW_RESIZABLE)
#initWindow(cint(Window_size.x),cint(Window_size.y), "Antz")

#while not windowShouldClose():
    #if isWindowResized(): Window_size = (x: getScreenWidth().toFloat, y: getScreenHeight().toFloat)

    #beginDrawing()
    #clearBackground Raywhite
    
    #drawText("Steps: " & $steps,10,10,15,Black)
    #drawRectangleLines(cint(BUFFER_SCALE * Ant.y),cint(BUFFER_SCALE * Ant.x), BUFFER_SCALE, BUFFER_SCALE, Red) # Ant
    #tick_speed = sliderBar((x:100.0 , y:100.0, width: 100.0, height: 10.0),"ticks ",$tick_speed,tick_speed,0.0, 5.0)
    #steps_per_tick = uint(sliderBar((x:100.0 , y:150.0, width: 100.0, height: 10.0),"steps per tick ",$steps_per_tick,float(steps_per_tick),1.0, 500.0))
   # endDrawing()

proc update*() = 
    if play:
        if counter >= tick_speed:
            for _ in 1 .. steps_per_tick: # how much steps does the ant needs to do (its pretty boring so i speed it up)
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
            counter -= tick_speed
        counter += getFrameTime()

    
    if isKeyReleased(Space):
      play = not play

