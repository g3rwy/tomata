import bitops
#import tomata

const
  Size = 10
  LastBit = Size - 1
  Lines = Size div 2
  Rule = 250
 
type State =  array[Size,bool] 

template bitVal(state: State; n: typed): int = 
  ord(state[LastBit - n] == true)

proc setB(state: var State,x : int) =
  state[LastBit - x] = true

proc ruleTest(x: int): bool = 
  ## Return true if a bit must be set.
  (Rule and 1 shl (7 and x)) != 0


#var newState : State

proc evolve(state: var State) =
  var newState: State  # All bits are 0, can get rid of it in future, its not necessary
  if ruleTest(state.bitVal(0) shl 2 or state.bitVal(LastBit) shl 1 or state.bitVal(LastBit-1)):
    newState.setB(LastBit) # !!!!!!! this needs to be changed when i use bit array or bool array !!!!!

  if ruleTest(state.bitVal(1) shl 2 or state.bitVal(0) shl 1 or state.bitVal(LastBit)):
    newState.setB(0) # !!!!!!! this needs to be changed when i use bit array or bool array !!!!!

  for i in 1..<LastBit:
    if ruleTest(state.bitVal(i + 1) shl 2 or state.bitVal(i) shl 1 or state.bitVal(i - 1)):
      newState.setB(i) # !!!!!!! this needs to be changed when i use bit array or bool array !!!!!

  state = newState
 
proc testB(state : State, n : int) : bool =
  state[LastBit - n] == true

proc show(state: State) = # !!!!!!! this needs to be changed when i use bit array or bool array !!!!!
  ## Show the current state.
  for i in countdown(LastBit, 0):
    stdout.write if state.testB(i): '*' else: ' '
  echo ""
 
var 
  state: State
  base_state = cast[ptr State](addr state)
  #next_state = cast[ptr State](addr newState)

base_state[].setB(Lines)

for _ in 1..Lines:
  show(state)
  evolve(state)