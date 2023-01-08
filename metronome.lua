-- metronome v0.0.1
-- Bing, buk, buk, buk
--
-- A screen flash and
-- sound mimic a
-- metronome
--
-- K2: Start, stop
-- K3: Switch mode
--
-- In Main mode:
-- E1: Tempo
-- E2: Whole level
-- E3: Subdivion level
--
-- In Signature mode:
-- E1: Subdivision length
-- E2: Upper number
-- E3: Lower number

util = require "util"
fileselect = require "fileselect"

--tick along
function ticker()
  while isPlaying do
    if clockPosition > count.whole then -- we're on the barline
      clockPosition = 0  --loop clock
      count.smallBeat = false
      count.bigBeat = true
      screen_dirty = true
    else if clockPosision % count.subBeatLength == 0 then -- we're on a subcount
      --play a big sound
      count.smallBeat = false
      count.bigBeat = true
      screen_dirty = true
    else if clockPosition % count.beatLength == 0 then -- we're on a small beat
      -- play a small sound
      count.bigBeat = false
      count.smallBeat = true
      screen_dirty = true
    else 
      --anything here?
      --count.bigBeat = false
      --count.smallBeat = false
    end
    clockPosition = clockPosition + tick -- move to next clock position
    clock.sync(1/192) -- and wait for a tick
  end
end

function redraw_clock() ----- a clock that draws space
  while true do ------------- "while true do" means "do this forever"
    clock.sleep(1/15) ------- pause for a fifteenth of a second (aka 15fps)
    if screen_dirty then ---- only if something changed
      redraw() -------------- redraw space
      screen_dirty = false -- and everything is clean again
    end
  end
end

function init()
  redraw_clock_id = clock.run(redraw_clock) --add these for other clocks so we can kill them at the end

  -- start params
  params:add_separator("Metronome")
  params:add_number("upperNumber", "Upper Number", 1, 128, 4)
  params:set_action("upperNumber",   function upper_update(x)
    uppernumber = upperNumber + x
    count.recalculate()
  end)
  params:add_number("lowerNumber", "Lower Number", 1, 32, 4)
  params:set_action("lowerNumber", function lower_update(x)
    lowerNumber = lowerNumber + x
    count.recalculate()
  end)
  params:add_number("subcount", "Small Count", 0, upperNumber, 4)
  params:set_action("subcount", function subcount_update(x)
    subcount = util.clamp(subcount + x, 1, upperNumber)
  end)  
  params:bang() -- set defaults using above params
  --end params
  
  count = {}
  count.beatLength = 0
  count.subBeatLength = 0
  count.whole = 768
  count.recalculate = function()
    count.beatLength = count.whole / lowerNumber
    count.subBeatLength = count.beatLength * subcount
  end
  count.bigBeat = false
  count.smallBeat = false

  --could use these to make the lower number start with powers of 2?
  --segmentLength = 6 -- index to read from resolutions, i.e. resolutions[segmentLength]
  --resolutions = {1,2,3,4,6,8,12,16,24,32,48,64,96,128,192}

  --drawing stuff
  beatScreen = 0 --screen level: set to 15 when the metronome pings to flash the screen
  heldKeys = {false, false, false}
  isPlaying = false -- are we playing right now?

  theClock = clock.run(ticker) -- sequencer clock
  clockPosition = 0 -- sequencer position right now. Updated by function 'ticker'
  tick = 1 -- how much to increment each tick. Guess it could be used for double time?

  signatureView = false -- are we looking at samples?

  --file = {} --add samples: could be used to load bing samples
  
  screenDirty = true -- make sure we draw screen straight away

end

-- draws the view
function drawView()

  --set screen level based on whether we're in a big or sub beat
  if count.bigBeat then beatScreen = 15 
  else if count.smallBeat then beatScreen = 4 
  else beatScreen = 0 end

  --draw black or white background
  screen.level(beatScreen)
  screen.rect(0,0,127,63)
  screen.fill()
  
  --draw white or black text
  screen.level(15 - beatScreen)
  
  --what view we in?
  screen.move(0,0)
  if mainView then screen.text("Levels")
  else screen.text("Signature") end
  
  -- could we highlight stuff depending what view we're in?
  
  --time signature, big nice text
  screen.move(64,64)
  screen.text(upperNumber)
  screen.move(64,74)
  screen.text(lowerNumber)
  --tempo
  screen.move(10,120)
  screen.text(clock.get_tempo())
  --count
  --programmatically, draw text representing the counts in the count
  -- e.g. ONE two three FOUR five
  --etc
  
  screen.fill()

end

-- draw the display!
function redraw()
  screen.clear()

  drawView()

  screen.update()
end

function enc(e, d)

  if e == 1 and mainView then
    local tempoh = clock.get_tempo() + d
    params:set(“clock_tempo”, tempoh)
  else
    subcount_update(d)
  end
  
  if e == 2 and mainView then
    -- set big beat playback sound
  else
    upper_update(d)
  end
  
  if e == 3 and mainView then
    --set small beat playback sound
  else 
    lower_update(d)
  end

end

function key(k, z)
  
  if k == 2 then
    if isPlaying then isPlaying = false
    else isPlaying = true end
  end
  
  if k == 3 then -- togle view
    if mainView then mainView = false
    else mainView = true end
  end

end

function cleanup() --------------- cleanup() is automatically called on script close
  clock.cancel(redraw_clock_id) -- melt our clock via the id we noted
end
