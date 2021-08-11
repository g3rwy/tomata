import nimraylib_now
import math
const
  WIDTH = 600'u
  HEIGHT = 600'u

proc map(value, a_start,a_end,b_start,b_end:float) : float = b_start + ((value - a_start) * (b_end - b_start)) / (a_end - a_start)

initWindow(cint(WIDTH),cint(HEIGHT), "Mandelbrot")
setTargetFPS(144)

var
    a = 0.0
    b = 0.0
    ca = a
    cb = b
    n = 0
    aa = 0.0
    bb = 0.0
    scale = 1.0

while not windowShouldClose():
    beginDrawing()
    clearBackground(Raywhite)
    for y in 0 .. HEIGHT:
        for x in 0 .. WIDTH:
            a = map(y.float,0.0,HEIGHT.float,-scale,scale)
            b = map(x.float,0.0,WIDTH.float,-scale,scale)

            ca = a
            cb = b

            n = 0
            while n < 50:
                aa = a^2 - b^2
                bb = 2 * a * b
                a = aa + ca
                b = bb + cb
                if a + b > 20:
                    break
                inc n
            var bright = map(n.float,0.0,50.0,0.0,1.0)
            drawPixel(x.cint,y.cint,colorFromNormalized((bright,bright,bright,1.0)))

    scale = sliderBar((x:30.0,y:15.0,width:500.0,height:10.0),"scale",$scale,scale,0.1,2.0)
    endDrawing()