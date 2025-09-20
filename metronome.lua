-- metronome v0.0.2
-- Bing, buk, buk, buk
--
-- A screen flash and
-- sound mimic a
-- metronome
--
-- K2 or K3: Start, stop
--
-- E1: Subcount
-- E2: Count
-- E3: Subdivision
--
-- Hold K1, turn E1:
-- adjust norns tempo
--
-- See params menu
-- for many options
-- including sound, midi
-- and crow

util = require "util"
fileselect = require "fileselect"
MusicUtil = require("musicutil")
engine.name = 'PolyPerc'
nb = require "metronome/lib/nb"

local g
g = grid.connect()

--tick along
function ticker()
  while isPlaying do
    if clockPosition > count.barlength then -- we're on the barline
      clockPosition = 0
      beatScreen = 15
      count.number = math.floor((clockPosition / count.barlength) * params:get("upperNumber") + 1)
			play_something(beatFreq, beatVol, 1)
    else if math.floor(clockPosition % count.subBeatLength) == 0 then -- we're on a subcount
      --play a big sound
      beatScreen = 6
      count.number = math.floor((clockPosition / count.barlength) * params:get("upperNumber") + 1)
			play_something(beatFreq, subBeatVol, 1)
    else if math.floor(clockPosition % count.beatLength) == 0 then -- we're on a small beat
      -- play a small sound
      beatScreen = 3
      count.number = math.floor((clockPosition / count.barlength) * params:get("upperNumber") + 1)
      play_something(subBeatFreq, subBeatVol, 2)
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

function play_something(freq, amp, sample)
	if note_output == 1 then --engine
		engine.amp(amp)
		engine.hz(freq) 
	end
	if note_output == 2 then --sample
	  softcut.level(sample, amp)
	  softcut.position(sample, 0)
	  softcut.play(sample, 1)
	end
	if note_output == 3 then --nb
  	local player = params:lookup_param("voice_id"):get_player()
    player:play_note(MusicUtil.freq_to_note_num(freq), amp, params:get("engine_decay") / 1000)
      end
	if note_output == 4 then --MIDI
		play_midi_note(MusicUtil.freq_to_note_num(freq), math.floor(64 * amp), params:get("engine_decay") / 1000)
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
  nb:init()
  redraw_clock_id = clock.run(redraw_clock) --add these for other clocks so we can kill them at the end
  
  --variables
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
  beatFreq = 110
	beatVol = 1.0
  subBeatFreq = 220
	subBeatVol = 0.5
  
  --voice variables
  note_destinations = {"engine", "sample", "nb voice", "midi out"}
  function play_midi_note(note, duration, velocity)  
    midi_device[midi_target]:note_on(note, velocity)
    local note_time = clock.get_beat_sec() * duration * 4 - 0.01
    clock.run(
      function()
        clock.sleep(note_time)
        midi_device[midi_target]:note_off(note, 0)
      end
    )
  end

	-- softcut variables
  -- clear buffer
  softcut.buffer_clear()
  for i=1, 2, 1 do
    -- global
    softcut.enable(i,1)
    softcut.buffer(i,i)
    -- level
    softcut.level(i,1.0)
    softcut.level_slew_time(i,0)
		softcut.fade_time(i, 0)
    softcut.pan(i,0)
    -- time
    softcut.loop(i,0)
    softcut.loop_start(i, 0)
    softcut.loop_end(i, 10)
    softcut.position(i, 0)
    softcut.rate(i, 1.0)
    -- stop
    softcut.play(i,0)
  end

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
  params:add_number("subcount", "sub count", 1, 128, 4)
  params:set_action("subcount", function()
    count.recalculate()
  end)
  params:add_number("beat_note", "beat note", 0, 127, 36,
    function(param) return MusicUtil.note_num_to_name(param:get(), true) end)
  params:set_action("beat_note", function()
    beatFreq = MusicUtil.note_num_to_freq(params:get("beat_note"))
  end)
	params:add{
    type = "control", id = "beat_volume", name = "b1vol",
		controlspec = controlspec.dB, action = function(dB) 
			beatVol = dB
		end
  }
  params:add_number("sub_beat_note", "sub beat note", 0, 127, 48,
    function(param) return MusicUtil.note_num_to_name(param:get(), true) end)
  params:set_action("sub_beat_note", function()
    subBeatFreq = MusicUtil.note_num_to_freq(params:get("sub_beat_note"))
  end)
	params:add{
    type = "control", id = "sub_beat_volume", name = "b2vol",
		controlspec = controlspec.dB, action = function(dB) 
			subBeatVol = dB
		end
  }
  params:add{type="option", id="note_output", name="Output", options=note_destinations, default=1, action=function(x) note_output=x
	  if x==1 then --engine
	      params:show('engine_pw')
	      params:show('filter_cutoff')
	    else
	      params:hide('engine_pw') 
	      params:hide('filter_cutoff')
	  end
	  if x==2 then --samples
	    params:show('sample_1')
	    params:show('sample_2')
	    params:hide('engine_decay')
	  else 
	    params:hide('sample_1')
	    params:hide('sample_2')
			params:show('engine_decay') 
	  end
	  if x==3 then params:show('voice_id') else params:hide('voice_id') end
	  if x==4 then params:show('midi target') else params:hide('midi target') end
	  _menu.rebuild_params()
  end}
	for i = 1, 2, 1 do
	  local name = ''
		if i == 1 then name = 'beat sample' else name = 'subbeat sample' end
	  params:add_file("sample_"..i, name, "")
  	params:set_action("sample_"..i, function(x)
	    print("reading sample: "..x..", to buffer: "..i)
    	softcut.buffer_clear_channel(i)
    	--file, start_src, start_dst, dur, ch_src, ch_dst
    	softcut.buffer_read_mono(x, 0,0,10, 1,i)
  	end)
	end
	nb:add_param("voice_id", "nb voice") -- adds a voice selector param to your script.
  nb:add_player_params() -- Adds the parameters for the selected voices to your script.
  --MIDI--
	midi_device = {} -- container for connected midi devices
  midi_device_names = {}
  midi_target = 1
  for i = 1,#midi.vports do -- query all ports
    midi_device[i] = midi.connect(i) -- connect each device
    table.insert(midi_device_names, i..": "..util.trim_string_to_width(midi_device[i].name,80) -- value to insert
  end
  params:add_option("midi target", "MIDI Device",midi_device_names,1)
  params:set_action("midi target", function(x) midi_target = x end)
	--END MIDI--
  
  decay_spec = controlspec.def{
    min = 10, max = 2000, warp = 'exp', step = 1,
    default = 200, units = 'ms', quantum = 0.01, wrap = false,
  }
  params:add{
    type = "control", id = "engine_decay", name = "decay",
    controlspec = decay_spec, action = function(ms) engine.release(ms / 1000) end
  }
  params:add{
    type = "control", id = "engine_pw", name = "pulse width",
    controlspec = controlspec.def{min = 50, max = 99, warp = 'lin', step = 1, default = 50, units = '%', quantum = 0.01, wrap = false},
    action = function(width) engine.pw(width / 100) end
  }
  params:add{
    type = "control", id = "filter_cutoff", name = "cutoff",
		controlspec = controlspec.FREQ, action = function(freq) engine.cutoff(freq) end
  }
  
  -- here, we set our PSET callbacks for save / load:
  params.action_write = function(filename,name,number)
    os.execute("mkdir -p "..norns.state.data.."/"..number.."/")
    tab.save(rhythmicDisplay,norns.state.data.."/"..number.."/display.data")
    tab.save(noteEvents,norns.state.data.."/"..number.."/notes.data")
  end
  params.action_read = function(filename,silent,number)
    midi_device[midi_target]:cc(123,0,1) -- all notes off
    print("finished reading '"..filename.."'", number)
    note_data = tab.load(norns.state.data.."/"..number.."/display.data")
    rhythmicDisplay = note_data -- send this restored table to the sequins
    note_data = tab.load(norns.state.data.."/"..number.."/notes.data")
    noteEvents = note_data -- send this restored table to the sequins
    updateCursor()
    curYPos = math.floor((currentTrack - 1) * (screenHeight / tracksAmount))
  end
  params.action_delete = function(filename,name,number)
    print("finished deleting '"..filename, number)
    norns.system_cmd("rm -r "..norns.state.data.."/"..number.."/")
  end
  
  params:bang() -- set defaults using above params
  --end params

  --drawing stuff
  beatScreen = 0 --screen level: set to 15 when the metronome pings to flash the screen
  heldKeys = {false, false, false}
  isPlaying = false -- are we playing right now?

  --main clock
  theClock = clock.run(ticker) -- sequencer clock
  clockPosition = 0 -- sequencer position right now. Updated by function 'ticker'
  tick = 1 -- how much to increment each tick. Guess it could be used for double time?

  g:all(0)  --clear grid
  screenDirty = true -- make sure we draw screen straight away

end

-- draws the view
function drawView()

  --draw black or white background
  screen.level(beatScreen)
  screen.rect(0,0,127,63)
  screen.fill()
  
  --set level for all the following drawing
  screen.level(15 - beatScreen)
  --tempo
  screen.move(0,5)
  screen.text(clock.get_tempo())
  --time signature, big nice text
  screen.font_size(15)
  screen.font_face(63)
  screen.move(92,50)
  screen.text(params:get("upperNumber"))
  screen.move(92,64)
  screen.text(params:get("lowerNumber"))
  screen.font_face(0)
  screen.font_size(8)
  
  screen.move(127,5)
	screen.text_right("subcount: " .. params:get("subcount")) --subcount  
  --count
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
    if heldKeys[1] then --set tempo
      params:set("clock_tempo", clock.get_tempo() + d)
    else --set subcount
      local sc = params:get("subcount") + d
      params:set("subcount", sc)
    end
	end
  if e == 2 then --set upper number
    params:set("upperNumber", params:get("upperNumber") + d)
    if params:get("subcount") > params:get("upperNumber") then params:set("subcount", params:get("upperNumber")) end
  end
  if e == 3 then --set lower number
    params:set("lowerNumber", params:get("lowerNumber") + d)
  end
	if not isPlaying then
	  screen_dirty = true
	end
end

function key(k, z)
  heldKeys[k] = z == 1 --test and store held keys
  if k == 2 or 3 then --start/stop
    if z == 1 then
      if isPlaying then isPlaying = false
        clockPosition = 0
      else isPlaying = true 
        clock.run(ticker) end
    end
  end
	if not isPlaying then
	  screen_dirty = true
	end
end

function cleanup() --------------- cleanup() is automatically called on script close
  midi_device[midi_target]:cc(123,0,1) -- all notes off
  clock.cancel(redraw_clock_id) -- melt our clock via the id we noted
  -- should we melt the ticker clock too?
  clock.cancel(ticker_clock_id)
end
