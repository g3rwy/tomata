import nimraylib_now
import math
import lenientops
import complex
const
  W = 200
  H = 200
  MaxIter = 100

var
  mv_x = -0.5'f64
  mv_y = 0.0'f64
  Zoom = 0.5'f64

#proc map(value, a_start,a_end,b_start,b_end:float) : float = b_start + ((value - a_start) * (b_end - b_start)) / (a_end - a_start)

initWindow(cint(W),cint(H), "Mandelbrot")
setTargetFPS(144)

while not windowShouldClose():
    beginDrawing()
    clearBackground(Raywhite)
    for y in 0 .. H:
        for x in 0 .. W:
            var i = MaxIter - 1
            let c = complex((2 * x - W) / (W * Zoom) + mv_x, (2 * y - H) / (H * Zoom) + mv_y)
            var z = c
            while abs(z) < 2 and i > 0:
                z = z * z + c
                dec i
            drawPixel(x.cint,y.cint,colorFromHSV(i / MaxIter * 360, 1, i / MaxIter))
    mv_x = clamp(mv_x - 0.001,-1.050090000000004,1.0)
    mv_y = clamp(mv_y - 0.001,-0.3500000000000004,1.0)
    Zoom += 0.03
    endDrawing()