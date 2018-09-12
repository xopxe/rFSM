--
-- Simple timeevent demo that shows how to write portable FSM.
-- The rtp module is available here
-- https://github.com/kmarkus/rtp.gitg 
--

local rfsm = require "rfsm"
local rfsm_timeevent = require "rfsm_timeevent"
local hasrtp, rtp = pcall(require, "rtp")
if not hasrtp then rtp = nil end

local gettime

if rtt then
  require "rttlib"
  gettime = rtt.getTime
  print("using RTT timing services")
else
  if hasrtp then
    gettime = function() return rtp.clock.gettime("CLOCK_MONOTONIC") end
    print("using rtp timing services")
  else
    print("falling back on low resolution Lua time")
    gettime = function() return os.time(), 0 end
  end
end

--[[
function gettime()
   return rtp.clock.gettime("CLOCK_MONOTONIC")
end
--]]

rfsm_timeevent.set_gettime_hook(gettime)

return rfsm.csta {
  dbg=true,
  -- only for rfsm-sim
  idle_hook=function() uml(); os.execute("sleep 0.5") end,

  one = rfsm.sista{},
  two = rfsm.sista{},
  three = rfsm.sista{},
  four = rfsm.sista{},
  five = rfsm.sista{},

  rfsm.trans{ src='initial', tgt='one' },
  rfsm.trans{ src='one', tgt='two', events={ 'e_after(0.1)' } },
  rfsm.trans{ src='two', tgt='three', events={ 'e_after(0.2)' } },
  rfsm.trans{ src='three', tgt='four', events={ 'e_after(0.3)' } },
  rfsm.trans{ src='four', tgt='five', events={ 'e_after(0.4)' } },
  rfsm.trans{ src='five', tgt='one', events={ 'e_after(1)' } },
}
