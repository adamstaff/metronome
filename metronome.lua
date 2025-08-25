-- metronome v0.0.1
-- Bing, buk, buk, buk
--
-- A screen flash and
-- sound mimic a
-- metronome
--
-- K2 or K3: Start, stop
--
-- In Main mode:
-- E1: Subcount
-- E2: Whole level
-- E3: Subdivion level
--
-- Hold K1, turn E1:
-- adjust norns tempo

util = require "util"
fileselect = require "fileselect"
engine.name = 'PolyPerc'

local g
g = grid.connect()

--tick along
function ticker()
  while isPlaying do
    if clockPosition > count.barlength then -- we're on the barline
      clockPosition = 0
      beatScreen = 15
      count.number = math.floor((clockPosition / count.barlength) * params:get("upperNumber") + 1)
      engine.amp(1)
      engine.hz(100)
    else if clockPosition % count.subBeatLength == 0 then -- we're on a subcount
      --play a big sound
      beatScreen = 6
      count.number = math.floor((clockPosition / count.barlength) * params:get("upperNumber") + 1)
      engine.amp(0.5)
      engine.hz(100)
    else if clockPosition % count.beatLength == 0 then -- we're on a small beat
      -- play a small sound
      beatScreen = 3
      count.number = math.floor((clockPosition / count.barlength) * params:get("upperNumber") + 1)
      engine.amp(0.5)
      engine.hz(200)
    else
      --anything here?
      count.bigBeat = false
      count.smallBeat = false
    end
    end
    end
    clockPosition = clockPosition + tick -- move to next clock position
    clock.sync(1/192) -- and wait for a tick
  end
end

function redraw_clock() ----- a clock that draws space
  while true do ------------- "while true do" means "do this forever"
    clock.sleep(1/60) ------- pause for a fifteenth of a second (aka 15fps)
    if screen_dirty or isPlaying then ---- only if something changed
      redraw() -------------- redraw space
      screen_dirty = false -- and everything is clean again
    end
  end
end

function init()
  redraw_clock_id = clock.run(redraw_clock) --add these for other clocks so we can kill them at the end
  
  --variables
 -- upperNumber = 0
--  lowerNumber = 0
--  subcount = 0
  count = {}
  count.beatLength = 0
  count.subBeatLength = 0
  count.whole = 768
  count.barlength = 768
  count.recalculate = function()
    count.beatLength = count.whole / params:get("lowerNumber")
    count.subBeatLength = count.beatLength * params:get("subcount")
    count.barlength = count.whole * ((1 / params:get("lowerNumber")) * params:get("upperNumber"))
  end
  count.bigBeat = false
  count.smallBeat = false
  count.number = 1
  --end variables
  
  -- start params
  params:add_separator("Metronome")
  params:add_number("upperNumber", "Upper Number", 1, 128, 4)
  params:set_action("upperNumber", function()
    count.recalculate()
  end)
  params:add_number("lowerNumber", "Lower Number", 1, 32, 4)
  params:set_action("lowerNumber", function()
    count.recalculate()
  end)
  params:add_number("subcount", "Small Count", 1, 128, 4)
  params:set_action("subcount", function()
    count.recalculate()
  end)
  params:bang() -- set defaults using above params
  --end params

  --could use these to make the lower number start with powers of 2?
  --segmentLength = 6 -- index to read from resolutions, i.e. resolutions[segmentLength]
  --resolutions = {1,2,3,4,6,8,12,16,24,32,48,64,96,128,192}

  --drawing stuff
  beatScreen = 0 --screen level: set to 15 when the metronome pings to flash the screen
  heldKeys = {false, false, false}
  isPlaying = false -- are we playing right now?

  --main clock
  theClock = clock.run(ticker) -- sequencer clock
  clockPosition = 0 -- sequencer position right now. Updated by function 'ticker'
  tick = 1 -- how much to increment each tick. Guess it could be used for double time?

  mainView = false -- are we adjusting the tempo and levels?

  --file = {} --add samples: could be used to load bing samples
  engine.release(0.1)

  g:all(0)
  
  screenDirty = true -- make sure we draw screen straight away

end

-- draws the view
function drawView()

  --draw black or white background
  screen.level(beatScreen)
  screen.rect(0,0,127,63)
  screen.fill()
  
  --draw white or black text
  screen.level(15 - beatScreen)
  
  --what view we in?
  screen.move(0,5)
  screen.text(clock.get_tempo())
  
  -- could we highlight stuff depending what view we're in?
  
  --time signature, big nice text
  screen.move(96,49)
  screen.text(params:get("upperNumber"))
  screen.move(96,59)
  screen.text(params:get("lowerNumber"))
  
  screen.move(127,5)
  if mainView then
    screen.text_right("tempo: " .. clock.get_tempo()) --tempo
    else 
    screen.text_right("subcount: " .. params:get("subcount")) --subcount
  end
  
  --count
  --programmatically, draw text representing the counts in the count
  -- e.g. ONE two three FOUR five
  --etc
  screen.stroke()
  screen.level(1)
  if not isPlaying then
    screen.circle(32,36,24)
    else
    screen.arc(32,36,24, 0-math.pi/2, 2*math.pi * ((count.number) / (params:get("upperNumber"))) - (math.pi/2))
  end
  screen.line(32,36)
  screen.fill()
  screen.level(10)
  screen.arc(32,36,24, 0-math.pi/2, 2*math.pi * (clockPosition / count.barlength) - (math.pi/2))
  screen.line(32,36)
  screen.fill()
  screen.line_width(3)
  for i = 1, params:get("upperNumber") do
    screen.level(5)
    if i % params:get("subcount") == 0 then screen.level(10) end
    if i == params:get("upperNumber") then screen.level(16) end
    screen.arc(32,36,25, 2*math.pi * (i / params:get("upperNumber")) - (math.pi/2), 2*math.pi * (i / params:get("upperNumber")) - (math.pi/2) + 0.05)
    screen.stroke()
  end
  screen.move(96,20)
  screen.text(count.number)
  screen.move(80,32)
  if isPlaying then screen.text("playing")
  else screen.text("stopped") end 
  
  screen.fill()

  if beatScreen > 0 then 
    local beatinS = ((clock.get_tempo() * (4 / params:get("lowerNumber"))) / 60)
    local framesPerBeat = 60 / beatinS
    beatScreen = math.floor(beatScreen - (beatScreen / framesPerBeat)) 
  end
  
  --grid
  if isPlaying then
    local test = 1 + math.floor(16 * (count.number % 1 + (params:get("upperNumber") * (clockPosition / count.barlength))))
    --ticks
    for i = 1, 4 do
      for j = 1, 16 do
        --[[metronome swinger
        if i == 1 and j == test % 16 then
          local k = test % 32
          if k > 16 then k = math.floor(32 - k) end
          if k < 1 then k = 1 end
          print("j is "..j.." and k is "..k.." and i is "..i)
          g:led(9,i,15)
          g:led(11,i,15)
          g:led(k,i,15)
        else
          g:led(j,i,0)]]
        --alternating sides
          if j < 9 then
            if count.number % 2 == 1 then
              g:led(j,i,beatScreen)
            end
          else
            if count.number % 2 == 0 then
              g:led(j,i,beatScreen)
            end
          end
        --end
      end
    end
    --progress
    for i = 5, 8 do
      for j = 1, 16 do
        local lev
        if j < 16 * (clockPosition / count.barlength) then lev = 1 else
          lev = math.floor(10 * math.pow(1 - math.abs(j/16 - clockPosition / count.barlength), 24))
        end
        g:led(j,i,lev)
      end
    end
  else --if not playing
    --g:all(0)
  end
  g:refresh()

end

-- draw the display!
function redraw()
  screen.clear()

  drawView()

  screen.update()
end

function enc(e, d)

  if e == 1 then 
    if heldKeys[1] then
      params:set("clock_tempo", clock.get_tempo() + d)
    else
      local sc = params:get("subcount") + d
      params:set("subcount", sc)
    end
  end
  
  if e == 2 then
    if mainView then
    -- set big beat playback sound
    else
      params:set("upperNumber", params:get("upperNumber") + d)
      if params:get("subcount") > params:get("upperNumber") then params:set("subcount", params:get("upperNumber")) end
    end
  end
  
  if e == 3 then
    if mainView then
      --set small beat playback sound
    else 
      params:set("lowerNumber", params:get("lowerNumber") + d)
    end
  end
  
  screen_dirty = true
  
end

function key(k, z)
  
  heldKeys[k] = z == 1
  
  if k == 2 or 3 then
    if z == 1 then
      if isPlaying then isPlaying = false
        clockPosition = 0
      else isPlaying = true 
        clock.run(ticker) end
    end
  end
  
--  if k == 3 and z == 1 then -- togle view
--    if mainView then mainView = false
--    else mainView = true end
--  end

  screen_dirty = true

end

function cleanup() --------------- cleanup() is automatically called on script close
  clock.cancel(redraw_clock_id) -- melt our clock via the id we noted
end
