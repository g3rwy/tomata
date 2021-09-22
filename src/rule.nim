import nimraylib_now


  #WIDTH = 1280
  #HEIGHT = 640
  #SCALE = 2
  #Size = WIDTH div SCALE
  #LastBit = Size - 1
  #Lines = Size div 2

var
  SCALE* = 2
  Size* = 1000 div 2
  LastBit* = Size - 1
  Lines* = Size div 2

type
  State* =  array[2000,bool]
 


template bitVal*(state: State; n: typed): int = 
  ord(state[LastBit - n] == true)


proc setB*(state: var State,x : int) =
  state[LastBit - x] = true

proc ruleTest*(x: int, Rule : uint8): bool = 
  ## Return true if a bit must be set.
  (cast[int](Rule) and 1 shl (7 and x)) != 0

var 
  newState: State
  cached_lines* : array[700, State]
  curr_line* : uint = 0


proc compute*(state: var State, rule: uint8) =
  newState.reset # sets all bools to default value (0)
  if ruleTest(state.bitVal(0) shl 2 or state.bitVal(LastBit) shl 1 or state.bitVal(LastBit-1), rule):
    newState.setB(LastBit)

  if ruleTest(state.bitVal(1) shl 2 or state.bitVal(0) shl 1 or state.bitVal(LastBit), rule):
    newState.setB(0)

  for i in 1..<LastBit:
    if ruleTest(state.bitVal(i + 1) shl 2 or state.bitVal(i) shl 1 or state.bitVal(i - 1), rule):
      newState.setB(i)

  cached_lines[curr_line] = state
  state = newState
  inc curr_line
 
proc testB*(state : State, n : int) : bool =
  state[LastBit - n] == true

 
proc gen*(rule : uint8) =
  var state: State
  curr_line = 0
  state.setB(Lines)
  for _ in 1..Lines:
    compute(state,rule)

var
  lines_rendered* = 0
  time_4_line* = 0.01
  counter : float32 = 0
  cell_color* : Color = (r: 0, g:50, b:220, a:255)

proc show*(l: int) =
  for n in 0 ..< l:
    for i in countdown(LastBit, 0):
      if cached_lines[n].testB(i): drawRectangle(SCALE * i, SCALE * n, SCALE,SCALE, cell_color) else: continue

  if counter >= time_4_line:
    counter -= time_4_line
    inc lines_rendered
  

proc update*(rule : var uint8) = 
  counter += getFrameTime()
  if lines_rendered > Lines:
    lines_rendered = 0
    rule = cast[uint8](getRandomValue(1,255))
    gen(rule)

  if counter >= time_4_line:
    counter -= time_4_line
    inc lines_rendered

