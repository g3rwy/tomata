import nimraylib_now

var
  BUFFET_SCALE* = 2

type
  human = tuple[state: uint8, counter: uint8,reg_time: uint8]
  cell_grid = array[ 300, array[ 500 , human]] #! Solve the problem with dynamically changing array

var
  steps* : uint = 0
  buffer : cell_grid
  states_colors* : array[4, Color]
  play* : bool = true
  tick_speed* : float32 = 0.0 # default value is Delta
  counter : float32 = 0.0 # used to count when the tick should update
  
  healthy_ppl* = (300 * 500) - 1
  dead_ppl* = 0
  sick_ppl* = 1
  cured_ppl* = 0

  lethal* : cint = 6 # in % of deadly is virus

  #n : cell_grid
  base* = cast[ptr cell_grid](addr buffer)
  #next_step* = cast[ptr cell_grid](addr n)

states_colors = [
  Green,       # HEALTHY               0
  Red,         # INFECTED              1 # Maybe add wall here in future, when i will add feature to draw cells
  Darkgreen,   # CURED/WENT THROUGH    2
  Black        # DEAD                  3
]

proc infected_around(grid : var cell_grid, x,y: int) : int = 
  result = 0
  for i in -1 .. 1:
    for j in -1 .. 1:
      let col = (x + i + base[].len) mod base[].len     # col
      let row = (y + j + base[0].len) mod base[0].len   # row
      result += (grid[col][row].state == 1).ord

tick_speed = getFrameTime()
base[getRandomValue(0,300)][getRandomValue(0,300)].state = 1 # random person is infected

proc update*() = 
  if play:
    if counter >= tick_speed:
      for i ,c in base[].pairs:
        for j ,states in c.pairs:
          let c = base[i][j]
          if c.state > 1: continue

          if c.state == 1:
            if c.counter >= c.reg_time: # is cured
              if getRandomValue(0,100) >= (100 - lethal):
                base[i][j].state = 3
                dec sick_ppl
                inc dead_ppl

              else:
                base[i][j].state = 2
                dec sick_ppl
                inc cured_ppl

            else:
              inc base[i][j].counter
            continue
          
          let infected = base[].infected_around(i,j)
          
          if infected == 0:continue
          else:
            let is_infected = ((infected * 25) + 30) >= getRandomValue(1,235)

            if c.state == 0 and is_infected:
              base[i][j].state = 1 # gets infected
              base[i][j].reg_time = cast[uint8](getRandomValue(1,50))
              
              dec healthy_ppl
              inc sick_ppl

      inc steps
      counter -= tick_speed
    else:
      counter += getFrameTime()

  if isKeyReleased(Space):
    play = not play

  if isKeyReleased(Enter): # RESET
    base[] = default(cell_grid)
    base[getRandomValue(0,300)][getRandomValue(0,300)].state = 1 # random person is infected
    healthy_ppl = (300 * 500) - 1
    dead_ppl = 0
    sick_ppl = 1
    cured_ppl = 0