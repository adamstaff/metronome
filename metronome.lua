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
    --loop clock
    if (clockPosition > totalBeats) then clockPosition = 0 end
    --check if it's time for an event
    if (clockPosition == **some definition of position**) then
      --play a sound
      --set screen levels
      screen_dirty = true
    end
    clockPosition = clockPosition + tick -- move to next clock position
    clock.sync(1/192) -- and wait
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

  --params
  beatsAmount = 0 -- number of beats to sequence
  totalBeats = 0 -- number of ticks for the sequencer clock
  -- start params
  params:add_separator("Metronome")
  params:add_number("upperNumber", "Upper Number", 1, 128, 4)
  params:set_action("upperNumber",   function upper_update(x)
    uppernumber = x
    -- something to recalculate tick length
  end)
  params:add_number("lowerNumber", "Lower Number", 1, 32, 4)
  params:set_action("lowerNumber", function lower_update(x)
      lowerNumber = x
      --totalBeats = 192 * beatsAmount
      --something to recalculate the bings
    end)
  params:bang() -- set defaults using above params
  --end params

-- could use these to make the lower number start with powers of 2?
  --segmentLength = 6 -- index to read from resolutions, i.e. resolutions[segmentLength]
  --resolutions = {1,2,3,4,6,8,12,16,24,32,48,64,96,128,192}

  --drawing stuff
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

  --set inversion based on whether we're in a big or sub beat

  --draw black or white background
  
  --draw white or black text
  --time signature, big nice text
  --tempo
  --count

end

-- draw the display!
function redraw()
  screen.clear()

  drawView()

  screen.update()
end

function enc(e, d)

  if e == 1 and mainView then
  
  else
  
  end
  
  if e == 2 and mainView then
  
  else
  
  end
  
  if e == 3 and mainView then
  
  else 
  
  end

end

function key(k, z)
  
  if k == 2 then
  
  end
  
  if k == 3 then
  
  end

end

function cleanup() --------------- cleanup() is automatically called on script close
  clock.cancel(redraw_clock_id) -- melt our clock via the id we noted
end
