import nimraylib_now

const
  MAX_FPS = 60

var
  Window_size = Vector2(x:1280,y:720)

setConfigFlags(WINDOW_RESIZABLE)
initWindow(cint(Window_size.x),cint(Window_size.y), "Game of Life")

setTargetFPS(MAX_FPS)

when isMainModule:
  echo("Hello, World÷!")

  while not windowShouldClose():
    if isWindowResized(): Window_size = (x: getScreenWidth().toFloat, y: getScreenHeight().toFloat)

    beginDrawing()
    clearBackground Raywhite
    #discard windowBox((x:50.0,y:50.0,width:0.7 * Window_size.x,height:0.7 * Window_size.y),"Warning!") # okay it seems like resizing UI works
    endDrawing()

closeWindow()