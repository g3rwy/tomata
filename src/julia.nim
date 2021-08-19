import lenientops
import nimraylib_now
import math
import simd/x86_avx
import simd/x86_avx2
from system import compileOption

const
  WIDTH = 800
  HEIGHT = 450
  
  half_W = WIDTH / 2
  half_H = HEIGHT / 2

  x_something = 1.5
  y_something = 1.0

  MaxThreads = 10

var
  Cy = -0.2321
  Cx = -0.835
  
when WIDTH mod 4 != 0:
  raise newException(ValueError,"The WIDTH of window must be dividable by 4")

when compileOption("threads"):
  import locks
  var thr : array[0 .. MaxThreads - 1, Thread[void]]
  when WIDTH mod MaxThreads != 0:
    raise newException(ValueError,"The WIDTH of window must be dividable by amount of Threads")

var
  nIterations : int = 600

  pFractal : array[WIDTH * HEIGHT,int64]  
  MoveX = 0.0
  MoveY = 0.0
  Zoom = 1.0

initWindow(cint(WIDTH),cint(HEIGHT), "Julia set")
#setTargetFPS(144)

proc CreateJuliaSet() =
  var
    a,b,mask1,two,four : m256d
    zr,zi,zr2,zi2,cr,ci : m256d
    c,n,mask2,one,iterations : m256i

    # --- Constants ---
  one = set1_epi64x(1)

  two = set1_pd_256(2.0)

  four = set1_pd_256(4.0)

  cr = set1_pd_256(Cx)
  ci = set1_pd_256(Cy)

    # ------------------

  iterations = set1_epi64x(nIterations)

  let
    x_scale = (0.5 * Zoom * WIDTH)
    y_scale = (0.5 * Zoom * HEIGHT)


  for y in 0 ..< HEIGHT:
    let cached_zi = y_something * (y - half_H) / y_scale + MoveY

    for x in countup(0 , WIDTH - 1 , 4):
      #TODO get rid of this entire computation
      zr = set_pd(x_something * (x - half_W) / x_scale + MoveX, x_something * (x + 1 - half_W) / x_scale + MoveX, x_something * (x + 2 - half_W) / x_scale + MoveX, x_something * (x + 3 - half_W) / x_scale + MoveX)     
      zi = set1_pd_256(cached_zi)

      n = setzero_si256()
      while true:
        zr2 = mul_pd(zr, zr)
          # (z.re * z.re)

        zi2 = mul_pd(zi,zi)
          #(z.im * z.im)
    
        a = sub_pd(zr2,zi2) 
        a = add_pd(a,cr) # a = (zr^2 - zi^2) + cr

        b = mul_pd(zr,zi) 
        b = mul_pd(b, two) 
        b = add_pd(b, ci) # b = (zr * zi) * 2.0 + ci

        # because no fmadd in bindings >:C
        zr = a
        zi = b
        
        a = add_pd(zr2,zi2) # getting sum of zi^2 and zr^2
        
        mask1 = cmp_pd(a,four,CMP_LT_OQ) # shows true for a < 4, correctly because a 
        
        mask2 = cmpgt_epi64(iterations,n) # shows true for iterations > n
        mask2 = and_si256(mask2, castpd_si256(mask1)) # shows true for mask2 AND mask
        
        c = and_si256(one, mask2)
        n = add_epi64(n,c)
        
        if movemask_pd(castsi256_pd(mask2)) == 0: # if its greater than 0, repeat, sh
            break

      let ints = cast[ptr UncheckedArray[int64]](n.addr)
      pFractal[y * WIDTH + x + 3] = ints[0]
      pFractal[y * WIDTH + x + 2] = ints[1]
      pFractal[y * WIDTH + x + 1] = ints[2]
      pFractal[y * WIDTH + x + 0] = ints[3]
      #pFractal[y * WIDTH + x] = n

when compileOption("threads"):
  proc CreateWithThreads() = 
    let
      SectionWidth = WIDTH div MaxThreads
      FractalWidth : float = HEIGHT / MaxThreads
    
    for i in 0 ..< MaxThreads:
      createThread thr[i], CreateJuliaSet
    
    thr.joinThreads()

var counter = 0.0

while not windowShouldClose():
  when compileOption("threads"):
    CreateWithThreads()
  else:
    CreateJuliaSet()
  
  counter += getFrameTime() / 3
  Cx = sin(counter)
  Cy = cos(counter)

  if isKeyDown(Space):
    nIterations += 10
  elif isKeyDown(Right_Shift):
    nIterations -= 10


  if isKeyDown(Left):
    MoveX -= 0.04 / Zoom
  elif isKeyDown(Right):
    MoveX += 0.04 / Zoom

  if isKeyDown(Up):
    MoveY -= 0.04 / Zoom
  elif isKeyDown(Down):
    MoveY += 0.04 / Zoom

  if isKeyDown(Left_bracket):
    Zoom *= 0.99
  elif isKeyDown(Right_bracket):
    Zoom *= 1.01

  beginDrawing()
  clearBackground(Raywhite)
  for x in 0 ..< WIDTH:
    for y in 0 ..< HEIGHT:
      let
        i : int64 = pFractal[y * WIDTH + x]
        i_u8 = uint8(i)

      drawPixel(x,y,Color(r: i_u8 ,g:  uint8(i_u8 * 1.5),b: uint8(i_u8 * 1.8),a: 255))

  drawText("iterations: " & $nIterations,10,30,10,Violet)  
  endDrawing()

closeWindow()