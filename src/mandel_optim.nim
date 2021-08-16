import nimraylib_now
import std/monotimes
import complex,lenientops,math
import simd/x86_avx
import simd/x86_avx2
import locks

const
    WIDTH = 800
    HEIGHT = 450
    MaxThreads = 10

when WIDTH mod 4 != 0:
    raise newException(ValueError, "The width must be dividable by 4")

when WIDTH mod MaxThreads != 0:
    raise newException(ValueError, "The width must be dividable by amount of threads")

# 921 600 pixels to compute in one frame, almost a million
type
    vi2d = tuple[x : int, y : int]
    vd2d = tuple[x: float64, y: float64]

var
    vScale : vd2d =  (WIDTH / 2.0 , HEIGHT.toFloat)
    vOffset : vd2d = (-1.5, -0.5)
    pFractal : array[WIDTH * HEIGHT,int64]
    
    nIterations : int = 128
    
    pix_tl : vi2d =   (0 , 0)
    pix_br : vi2d =   (WIDTH,HEIGHT)
    fract_tl : vd2d = (-2.0,-1.0)
    fract_br : vd2d = (1.0 , 1.0)
    test : m256d
    
    thr : array[0 .. MaxThreads - 1, Thread[tuple[p_tl,p_br : vi2d, fr_tl,fr_br:  vd2d, it: int]]] # needs --threads:on


proc screenToWorld(n : var vi2d, v: var vd2d) =
    v.x = n.x.toFloat / vScale.x + vOffset.x
    v.y = n.y.toFloat / vScale.y + vOffset.y

proc CreateFractalBasic(pix_tl,pix_br : var vi2d, fract_tl,fract_br: var vd2d, iterations: int) =
    let
        x_scale: float = (fract_br.x - fract_tl.x) / (float64(pix_br.x) - float64(pix_tl.x))
        y_scale: float = (fract_br.y - fract_tl.y) / (float64(pix_br.y) - float64(pix_tl.y))
    
    for y in pix_tl.y ..< pix_br.y:
        for x in pix_tl.x ..< pix_br.x:
            let c = complex(x * x_scale + fract_tl.x , y * y_scale + fract_tl.y)
            var
                z = complex(0.0 , 0.0)
                n : int = 0 # lol kinda want to limit the iterations, not to use entire int but uint16 is enough 
            
            while abs(z) < 2.0 and n < iterations:
                z = (z * z) + c
                inc n

            pFractal[y * WIDTH + x] = n

proc CreateFractalPreCalc(pix_tl,pix_br : var vi2d, fract_tl,fract_br: var vd2d, iterations: int) =
    let
        x_scale: float = (fract_br.x - fract_tl.x) / (float64(pix_br.x) - float64(pix_tl.x))
        y_scale: float = (fract_br.y - fract_tl.y) / (float64(pix_br.y) - float64(pix_tl.y))
        row_size: int = WIDTH
    var
        x_pos : float = fract_tl.x
        y_pos : float = fract_tl.y
        y_offset: int = 0

    for y in pix_tl.y ..< pix_br.y:
        x_pos = fract_tl.x
        for x in pix_tl.x ..< pix_br.x:
            let c = complex(x_pos, y_pos)
            var
                z = complex(0.0 , 0.0)
                n : int = 0
            
            while ((z.re * z.re) + (z.im * z.im)) < 4.0 and n < iterations:
                z = (z * z) + c
                inc n
            pFractal[y_offset + x] = n
            x_pos += x_scale
        # precalculating how many rows we got already             
        y_pos += y_scale
        y_offset += row_size
# pix_tl,pix_br : vi2d, fract_tl,fract_br:  vd2d, Iterations: int

proc CreateFractalIntrinsics(t : tuple[p_tl,p_br : vi2d, fr_tl,fr_br : vd2d, it: int]) {.thread.} =
    let
        x_scale: float = (t.fr_br.x - t.fr_tl.x) / (float64(t.p_br.x) - float64(t.p_tl.x))
        y_scale: float = (t.fr_br.y - t.fr_tl.y) / (float64(t.p_br.y) - float64(t.p_tl.y))
        row_size: int = WIDTH
    var
        y_pos : float = t.fr_tl.y
        y_offset = 0

        a,b,mask1,two,four : m256d
        zr,zi,zr2,zi2,cr,ci : m256d
        x_pos,m_x_scale,x_jump,x_pos_offsets : m256d

        c,n,mask2,one,iterations : m256i

        # --- Constants ---
    one = set1_epi64x(1)

    two = set1_pd_256(2.0)

    four = set1_pd_256(4.0)
        # ------------------

    iterations = set1_epi64x(t.it)

    m_x_scale = set1_pd_256(x_scale)
    x_jump = set1_pd_256(x_scale * 4)
    x_pos_offsets = set_pd(0, 1, 2, 3)
    x_pos_offsets = mul_pd(x_pos_offsets,m_x_scale)

    for y in t.p_tl.y ..< t.p_br.y:
        a = set1_pd_256(t.fr_tl.x)
        x_pos = add_pd(a,x_pos_offsets)

        ci = set1_pd_256(y_pos)

        for x in countup(t.p_tl.x, t.p_br.x - 1, 4):
            cr = x_pos

            zr = setzero_pd()
            zi = setzero_pd()
            n = setzero_si256()

            while true:
                zr2 = mul_pd(zr, zr)
                # (z.re * z.re)
                
                zi2 = mul_pd(zi,zi)
                #(z.im * z.im)
                
                a = sub_pd(zr2,zi2) # correct
                a = add_pd(a,cr) # correct

                b = mul_pd(zr,zi) # correct

                b = mul_pd(b, two) # correct
                b = add_pd(b, ci) # correct
                # because no fmadd in bindings >:C

                zr = a
                zi = b

                a = add_pd(zr2,zi2) # getting sum of zi^2 and zr^2

                mask1 = cmp_pd(a,four,CMP_LT_OQ) # shows true for a < 4, correctly because a = 0

                mask2 = cmpgt_epi64(iterations,n) # shows true for iterations > n
                mask2 = and_si256(mask2, castpd_si256(mask1)) # shows true for mask2 AND mask1, so x < 4 and iterations > n
                

                c = and_si256(one, mask2)
                n = add_epi64(n,c) # only 1 iteration
                
                if movemask_pd(castsi256_pd(mask2)) == 0: # if its greater than 0, repeat, should break only if its all 0
                    break

            x_pos = add_pd(x_pos, x_jump)
            
            let ints = cast[ptr UncheckedArray[int64]](n.addr)
            pFractal[y_offset + x + 3] = ints[0]
            pFractal[y_offset + x + 2] = ints[1]
            pFractal[y_offset + x + 1] = ints[2]
            pFractal[y_offset + x + 0] = ints[3]

        y_pos += y_scale
        y_offset += row_size

proc CreateFractalThreadPool(pix_tl,pix_br : var vi2d, fract_tl,fract_br: var vd2d, Iterations: int) =
    let
        SectionWidth = (pix_br.x - pix_tl.x) div MaxThreads
        FractalWidth : float = (fract_br.x - fract_tl.x) / MaxThreads

    for i in 0 ..< MaxThreads:
        createThread thr[i] , CreateFractalIntrinsics , (p_tl : (int(pix_tl.x + SectionWidth * i),pix_tl.y) , p_br: (int(pix_tl.x + SectionWidth * (i + 1)), pix_br.y), fr_tl: (float(fract_tl.x + FractalWidth * float(i)),fract_tl.y), fr_br: (float(fract_tl.x + FractalWidth * float(i + 1)),fract_br.y), it: Iterations)
    
    thr.joinThreads()


initWindow(WIDTH,HEIGHT,"Mandelbrot Optimized")

#setTargetFPS(60)

while not windowShouldClose():
    if isKeyDown(Left):
        vOffset.x -= 7 / vScale.x
    elif isKeyDown(Right):
        vOffset.x += 7 / vScale.x

    if isKeyDown(Up):
        vOffset.y -= 7 / vScale.y
    elif isKeyDown(Down):
        vOffset.y += 7 / vScale.y
    
    if isKeyReleased(Space):
        nIterations = clamp(nIterations + 32,32,int.high)
    if isKeyReleased(Enter):
        nIterations = clamp(nIterations - 32,32,int.high)
    
    if isKeyDown(LEFT_BRACKET):
        vScale.x -= vScale.x / 10
        vScale.y -= vScale.y / 10

    elif isKeyDown(RIGHT_BRACKET):
        vScale.x += vScale.x / 10
        vScale.y += vScale.y / 10

    #vScale.y += scroll 
    #vScale.x += scroll
    
    let delta = getFrameTime()
    screenToWorld(pix_tl, fract_tl)
    screenToWorld(pix_br, fract_br)

    let start = getMonoTime()
    CreateFractalThreadPool(pix_tl, pix_br, fract_tl, fract_br, nIterations)
    #CreateFractalIntrinsics(pix_tl, pix_br, fract_tl, fract_br, nIterations)
    #CreateFractalBasic(pix_tl, pix_br, fract_tl, fract_br, nIterations)
    #CreateFractalPreCalc(pix_tl, pix_br, fract_tl, fract_br, nIterations)
    
    let stop = getMonoTime()
    
    beginDrawing()
    clearBackground(Gray)
    let a = 0.1
    for y in pix_tl.y ..< pix_br.y:
        for x in pix_tl.x ..< pix_br.x:
            let
                i : int64 = pFractal[y * WIDTH + x]
                n = float32(i)
            drawPixel(x,y, Color(r: uint8((0.5f * sin(a * n) + 0.5f) * 255) , g: uint8((0.5f * sin(a * n + 2.094f) + 0.5f) * 255) , b: uint8((0.5f * sin(a * n + 4.188f) + 0.5f) * 255) , a: 255))
    drawText("took: " & $(stop - start),10,10,10,Violet)
    drawText("offset" & $vOffset,10,20,10,Violet)
    drawText("iterations: " & $nIterations,10,30,10,Violet)
    #drawFPS(WIDTH - 70,15)
    endDrawing()

closeWindow()

#[ let
        x_scale: float = (fract_br.x - fract_tl.x) / (float64(pix_br.x) - float64(pix_tl.x))
        y_scale: float = (fract_br.y - fract_tl.y) / (float64(pix_br.y) - float64(pix_tl.y))
        row_size: int = WIDTH
    var
        y_pos : float = fract_tl.y
        y_offset = 0

        a,b,mask1,two,four : m256d
        zr,zi,zr2,zi2,cr,ci : m256d
        x_pos,m_x_scale,x_jump,x_pos_offsets : m256d

        c,n,mask2,one,iterations : m256i

        # --- Constants ---
    one = set1_epi64x(1)

    two = set1_pd_256(2.0)

    four = set1_pd_256(4.0)
        # ------------------

    iterations = set1_epi64x(Iterations)

    m_x_scale = set1_pd_256(x_scale)
    x_jump = set1_pd_256(x_scale * 4)
    x_pos_offsets = set_pd(0, 1, 2, 3)
    x_pos_offsets = mul_pd(x_pos_offsets,m_x_scale)

    for y in pix_tl.y ..< pix_br.y:
        a = set1_pd_256(fract_tl.x)
        x_pos = add_pd(a,x_pos_offsets)

        ci = set1_pd_256(y_pos)

        for x in countup(pix_tl.x, pix_br.x - 1, 4):
            cr = x_pos

            zr = setzero_pd()
            zi = setzero_pd()
            n = setzero_si256()

            while true:
                zr2 = mul_pd(zr, zr)
                # (z.re * z.re)
                
                zi2 = mul_pd(zi,zi)
                #(z.im * z.im)
                
                a = sub_pd(zr2,zi2) # correct
                a = add_pd(a,cr) # correct

                b = mul_pd(zr,zi) # correct

                b = mul_pd(b, two) # correct
                b = add_pd(b, ci) # correct
                # because no fmadd in bindings >:C

                zr = a
                zi = b

                a = add_pd(zr2,zi2) # getting sum of zi^2 and zr^2

                mask1 = cmp_pd(a,four,CMP_LT_OQ) # shows true for a < 4, correctly because a = 0

                mask2 = cmpgt_epi64(iterations,n) # shows true for iterations > n
                mask2 = and_si256(mask2, castpd_si256(mask1)) # shows true for mask2 AND mask1, so x < 4 and iterations > n
                

                c = and_si256(one, mask2)
                n = add_epi64(n,c) # only 1 iteration
                
                if movemask_pd(castsi256_pd(mask2)) == 0: # if its greater than 0, repeat, should break only if its all 0
                    break

            x_pos = add_pd(x_pos, x_jump)
            
            let ints = cast[ptr UncheckedArray[int64]](n.addr)
            pFractal[y_offset + x + 3] = ints[0]
            pFractal[y_offset + x + 2] = ints[1]
            pFractal[y_offset + x + 1] = ints[2]
            pFractal[y_offset + x + 0] = ints[3]

        y_pos += y_scale
        y_offset += row_size ]#