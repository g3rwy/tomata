import nimraylib_now

const
  MAX_FPS = 60

var
  W_width = 1280
  W_height = 720

setConfigFlags(WINDOW_RESIZABLE)
initWindow(W_width, W_height, "Game of Life")

#var camera = Camera()

setTargetFPS(MAX_FPS)

when isMainModule:
  echo("Hello, World÷!")
  while not windowShouldClose():
    beginDrawing()
    clearBackground Raywhite
    discard windowBox((x:50.0,y:50.0,width:0.2 * float(getScreenWidth()) ,height:0.2 * float(getScreenHeight())),"Warning!")git 
    endDrawing()

closeWindow()