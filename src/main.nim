## here is everything for the app
## Make libraries from other files
#! This should be compiled and run as one GUI app


import nimraylib_now
import rule as elementar

const
    W_WIDTH = 1280
    W_HEIGHT = 720 ## Window size

let
    automatas = ["Game of Life", "Ants" , "Elementar CA"]

var
    curr_tomata = 2
    CONTENT_W = 1000
    CONTENT_H = 500 ## Content size (Cellular automata and fractals)
    # ========== Elementar variables =========
    rule : uint8 = 250

SCALE = 2
initWindow(W_WIDTH,W_HEIGHT, "TOMATA")
setTargetFPS(144)

gen(rule)

proc update_Size(s: int): void = 
  Size = s div 2
  LastBit = Size - 1
  Lines = Size div 2

while not windowShouldClose():
    beginDrawing()
    clearBackground(Raywhite)
    drawRectangle(0,0,W_WIDTH,W_HEIGHT,Raywhite)
    drawRectangle(0,W_HEIGHT - CONTENT_H,CONTENT_W,CONTENT_H,Gray)
    
    case curr_tomata:
    of 0: # Game of Life
        discard
    of 1: # Ants
        discard
    of 2: # Elementar
        #drawRectangle(SCALE * 2, SCALE * 2, SCALE,SCALE, cell_color)
        for n in 0 ..< lines_rendered:
            for i in countdown(LastBit, 0): #? thinking of a way to get elementar to scale in good way, with size and all
                if cached_lines[n].testB(i): drawRectangle(SCALE * i, SCALE * n + W_HEIGHT - CONTENT_H, SCALE,SCALE, cell_color) else: continue
        update_counter()

    else:
        discard

    # |------------------ Just for testing ------------------

    drawText("Here should be: " & automatas[curr_tomata],(W_HEIGHT - CONTENT_H) div 2 + 100, CONTENT_H div 2, 20, Black)
    drawText("Here should be UI",W_WIDTH - 180, 400, 15, Black)
    #=======================================================================================

    if button((x:15.0,y:15.0,width:40.0,height:40.0),"<"):  curr_tomata = (curr_tomata - 1) + (automatas.len * (curr_tomata - 1 < 0).ord)
    
    let text_padding = (W_WIDTH - measureText(automatas[curr_tomata], 20)) div 2 # Used to center text
    drawText(automatas[curr_tomata], text_padding, 25, 20, Black)

    if button((x:W_WIDTH - 55.0,y:15.0,width:40.0,height:40.0),">"): curr_tomata = (curr_tomata + 1) mod automatas.len # Works
    
    endDrawing()

    case curr_tomata:
    of 0: # Game of Life
        discard
    of 1: # Ants
        discard
    of 2: # Elementar
        if CONTENT_W div CONTENT_H != 2:
            raise newException(ValueError,"!!!!!! the propotions of window must be 1:2 !!!!!!!")
        update(getFrameTime(),rule)

    else:
        discard

closeWindow()