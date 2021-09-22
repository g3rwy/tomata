import lenientops
import nimraylib_now
import math
import complex
import simd/x86_avx
import simd/x86_avx2

from system import compileOption

const
  WIDTH = 800
  HEIGHT = 450

  MaxThreads = 10

var
  Zoom = 2.0
  MoveX = 0.0
  MoveY = 0.0

type
  thread_julia = tuple[start,w,h:int]

when WIDTH mod 8 != 0: # 8 because of SIMD
  raise newException(ValueError,"The WIDTH of window must be dividable by 4")

when compileOption("threads"):
  import locks
  var thr : array[0 .. MaxThreads - 1, Thread[thread_julia]]
  when WIDTH mod MaxThreads != 0:
    raise newException(ValueError,"The WIDTH of window must be dividable by amount of Threads")


var
  nIterations : int = 50

  pFractal : array[WIDTH * HEIGHT,int32]

initWindow(cint(WIDTH),cint(HEIGHT), "Burning Ship")
#setTargetFPS(144)


proc CreateBurningShip() =
    let
        x_scale: float = 1.5 / float64(WIDTH) * Zoom 
        y_scale: float = 2.0 / float64(HEIGHT) * Zoom 

    for y in 0 ..< HEIGHT:
        for x in 0 ..< WIDTH:
            let c = complex(x * x_scale + -2.5 + MoveX, y * y_scale + -1.0 + MoveY)
            var xtemp : float
            
            var
                z = c
                n : int = 0 
            
            while z.re * z.re + z.im * z.im < 4.0 and n < niterations:
              xtemp = z.re * z.re - z.im * z.im + c.re
              z.im = 2.0 * abs(z.re * z.im) + c.im
              z.re = xtemp
              inc n

            pFractal[y * WIDTH + x] = n

proc CreateShipSIMD(p : thread_julia) = 
  let
    x_scale: float = 1.5 / float64(WIDTH) * Zoom 
    y_scale: float = 2.0 / float64(HEIGHT) * Zoom

  var
    a,b,mask1,two,four: m256
    zr,zi,zr2,zi2,cr,ci,abs_mask : m256

    c,n,mask2,one,iterations: m256i

    # --- Constants ---
  one = set1_epi32_256(1)

  two = set1_ps_256(2.0)

  four = set1_ps_256(4.0)

  abs_mask = castsi256_ps(set1_epi32_256(int32.high))
    # ------------------

  iterations = set1_epi32_256(nIterations)

  for y in 0 ..< p.h:
    ci = set1_ps_256(y * y_scale + -1.0 + MoveY)
    for x in countup(p.start,p.w - 1 , 8):
      # oh god what is this, i don't know how to get rid of it for now but i will know soon
      cr = set_ps(x * x_scale + -2.5 + MoveX,(x+1)  * x_scale + -2.5 + MoveX,(x+2)  * x_scale + -2.5 + MoveX, (x+3) * x_scale + -2.5 + MoveX,    (x+4) * x_scale + -2.5 + MoveX,(x+5)  * x_scale + -2.5 + MoveX,(x+6)  * x_scale + -2.5 + MoveX, (x+7) * x_scale + -2.5 + MoveX)

      zr = setzero_ps()
      zi = setzero_ps()
      n = setzero_si256()

      while true:

        #[              
         xtemp = z.re * z.re - z.im * z.im + c.re
         z.im = 2.0 * abs(z.re * z.im) + c.im
         z.re = xtemp
         inc n 
        ]#
        zr2 = mul_ps(zr, zr)
        # (z.re * z.re)
        
        zi2 = mul_ps(zi,zi)
        #(z.im * z.im)
        
        a = sub_ps(zr2,zi2) 
        a = add_ps(a,cr) 
        
        b = mul_ps(zr,zi)
        
        b = mul_ps(b, two) 
        #b = castsi256_ps(abs_epi32(castps_si256(b)))
        b = and_ps(b,abs_mask)
        b = add_ps(b, ci) 
        zr = a
        zi = b
        
        a = add_ps(zr2,zi2)
        
        mask1 = cmp_ps(a,four,CMP_LT_OQ) 

        mask2 = cmpgt_epi32(iterations,n) 
        mask2 = and_si256(mask2, castps_si256(mask1)) 
        
        c = and_si256(one, mask2)
        n = add_epi32(n,c)
        
        if movemask_ps(castsi256_ps(mask2)) == 0: # if its greater than 0, r
            break

        let ints = cast[ptr UncheckedArray[int32]](n.addr)
        pFractal[y * WIDTH + x + 7] = ints[0]
        pFractal[y * WIDTH + x + 6] = ints[1]
        pFractal[y * WIDTH + x + 5] = ints[2]
        pFractal[y * WIDTH + x + 4] = ints[3]
        pFractal[y * WIDTH + x + 3] = ints[4]
        pFractal[y * WIDTH + x + 2] = ints[5]
        pFractal[y * WIDTH + x + 1] = ints[6]
        pFractal[y * WIDTH + x + 0] = ints[7]

when compileOption("threads"):
  proc BurningThreads() = 
    let
      SectionWidth = WIDTH div MaxThreads
    
    for i in 0 ..< MaxThreads:
      createThread thr[i], CreateShipSIMD , (start: SectionWidth * i,w:WIDTH,h:HEIGHT)
    
    thr.joinThreads()

while not windowShouldClose():
  #CreateBurningShip()
  when compileOption("threads"):
    BurningThreads()
  else:
    CreateShipSIMD((start : 0, w: WIDTH, h: HEIGHT))

  if isKeyDown(Space):
    nIterations += 10
  elif isKeyDown(Right_Shift):
    nIterations -= 10

  if isKeyDown(Left):
    MoveX -= 0.01
  elif isKeyDown(Right):
    MoveX += 0.01

  if isKeyDown(Up):
    MoveY -= 0.01
  elif isKeyDown(Down):
    MoveY += 0.01

  if isKeyDown(Right_Bracket):
    Zoom *= 0.98
  elif isKeyDown(Left_Bracket):
    Zoom *= 1.01

  beginDrawing()
  clearBackground(Raywhite)
  for x in 0 ..< WIDTH:
    for y in 0 ..< HEIGHT:
      let
        i : int64 = pFractal[y * WIDTH + x]
        
      if i == nIterations:
        drawPixel(x,y,White)
      else:
        let i_u8 = uint8(i)
        drawPixel(x,y,Color(r: i_u8 ,g:  uint8(i_u8 * 1.5),b: uint8(i_u8 * 1.8),a: 255))

  drawText("iterations: " & $nIterations,10,30,10,Violet)  
  endDrawing()

closeWindow()