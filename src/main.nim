## here is everything for the app
## Make libraries from other files
## This should be compiled and run as one GUI app


import nimraylib_now

const
    W_WIDTH = 1280
    W_HEIGHT = 720 ## Window size
    CONTENT_W = 1020
    CONTENT_H = 650 ## Content size (Cellular automata and fractals)

let
    automatas = ["Game of Life", "Ants" , "Elementar CA"]

var
    curr_tomata = 0




initWindow(W_WIDTH,W_HEIGHT, "TOMATA")
setTargetFPS(144)


while not windowShouldClose():
    beginDrawing()
    
    #------------------ Just for testing ------------------
    drawRectangle(0,0,W_WIDTH,W_HEIGHT,Green)
    drawRectangle(0,W_HEIGHT - CONTENT_H,CONTENT_W,CONTENT_H,Red)

    drawText("Here should be: " & automatas[curr_tomata],(W_HEIGHT - CONTENT_H) div 2 + 100, CONTENT_H div 2, 20, Black)
    drawText("Here should be UI",W_WIDTH - 180, 400, 15, Black)
    #=======================================================================================

    if button((x:15.0,y:15.0,width:40.0,height:40.0),"<"):  curr_tomata = (curr_tomata - 1) + (automatas.len * (curr_tomata - 1 < 0).ord)
    
    let text_padding = (W_WIDTH - measureText(automatas[curr_tomata], 20)) div 2 # Used to center text
    drawText(automatas[curr_tomata], text_padding, 25, 20, Black)

    if button((x:W_WIDTH - 55.0,y:15.0,width:40.0,height:40.0),">"): curr_tomata = (curr_tomata + 1) mod automatas.len # Works
    
    endDrawing()

closeWindow()