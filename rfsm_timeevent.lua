--
-- This file is part of rFSM.
--
-- (C) 2010,2011 Markus Klotzbuecher, markus.klotzbuecher@mech.kuleuven.be,
-- Department of Mechanical Engineering, Katholieke Universiteit
-- Leuven, Belgium.
--
-- You may redistribute this software and/or modify it under either
-- the terms of the GNU Lesser General Public License version 2.1
-- (LGPLv2.1 <http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>)
-- or (at your discretion) of the Modified BSD License: Redistribution
-- and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
--    1. Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--    2. Redistributions in binary form must reproduce the above
--       copyright notice, this list of conditions and the following
--       disclaimer in the documentation and/or other materials provided
--       with the distribution.
--    3. The name of the author may not be used to endorse or promote
--       products derived from this software without specific prior
--       written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
-- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--


local utils=require("utils")
local assert = assert
local type = type
local tonumber = tonumber
local math = math
local string = string
local rfsm = require "rfsm"

--- This module extends the core rFSM model with time events.
-- A time-event is specified using the <code>e_after(timespec)</code>
-- or <code>e_at(timespec)</code>. A timespec is floating point value
-- in seconds.  (Note: currently only relative (e_after) timeevents
-- are implemented).<br><br>
--
-- This implementation intentionally omits the os-dependent aspect of
-- getting the current time. Hence, after loading this module an
-- appropriate <code>gettime</code> function must be installed by
-- using <code>set_gettime_hook(f)</code>, where <code>f</code> is a
-- function which returns two values: the absolute time in seconds and
-- nanoseconds (following the POSIX
-- <code>clock_nanosleep(2)</code>).<br><br>
--
-- The OROCOS RTT <code>rtt.getTime()</code> function returns the
-- expected values can thus can be used as a drop-in source of
-- time. Also other, lower resolution time sources can be easily used:
-- for example the Lua os.time() returns the number of seconds since
-- epoch (on most platforms!), and for second-resolution timeevents
-- can be used as follows <code>function gettime() return os.time(), 0
-- end </code><br><br>
--
-- The implementation consists of a preprocessing step that expands
-- the specification to e_after(timespec) to the canonical form
-- e_after(timespec)@source fqn and installs an entry handler to
-- stores the entry time. A second handler (._check_timeevent) is is
-- stored in the source state that when called, checks for expiration
-- and (possibly) generates the time event. A "master" timeevent check
-- function (check_act_timeevents) calls all check_ handlers of the
-- current active states during post_step_hook.

--module 'rfsm_timeevent'
local M = {}

local gettime = nil

--- Setup the gettime function to be used by this module.
-- @param f function which is expected to return a time in sec.
function M.set_gettime_hook(f)
   assert(type(f) == 'function', "set_gettime_hook: parameter not a function")
   gettime = f
end

--- Generate two timeevent manager functions.
-- returns two functions: reset and check. The first will reset the
-- internally stored time. The second checks if the timeevent has
-- become true and if yes raises the event 'name'.
-- @param name name of event to raise
-- @param timespec time after or at timeevent shall trigger.
-- @param sendf function to call for sending events
local function gen_rel_timeevent_mgr(name, timespec, sendf, fsm)
   assert(type(gettime) == 'function',
	  "rfsm_timeevent error. Failed to install handlers: no gettime function set.")

   local ts = timespec
   local tend = nil
   local tcur = nil
   local fired=false

   local reset = function ()
		    tcur = gettime()
		    tend = tcur + ts
		    fired=false
		    fsm.dbg("TIMEEVENT", "reset timevent " .. name ..
			    " cur: " .. tostring(tcur) .. ", end: " .. tostring(tend))
		 end

   local check = function ()
		    if fired then return end
		    tcur = gettime()
		    fsm.dbg("TIMEEVENT", "checking timevent " .. name ..
			    " cur: " .. tostring(tcur) .. ", end: " .. tostring(tend))
		    if tcur > tend == 1 then
		       sendf(name)
		       fired=true
		    end
		 end

   return reset, check
end

--- Pre-process timevents and setup handlers.
-- @param fsm initalized root fsm.
local function expand_timeevent(fsm)
   local function se(...) rfsm.send_events(fsm, ...) end

   fsm.info("rfsm_timeevent: time-event extension loaded")

   rfsm.mapfsm(function (tr, p)
		  if not tr.events then return end
		  for i=1,#tr.events do
		     local e = tr.events[i]
		     local timespec = tonumber(string.match(e, "e_after%((.*)%)"))
		     if timespec then
			local eexp = e .. '@' .. tr.src._fqn
			tr.events[i] = eexp
			local reset, check = gen_rel_timeevent_mgr(eexp, timespec, se, fsm)
			tr.src.entry=utils.advise('before', tr.src.entry, reset)
			tr.src._check_timeevent = check
		     end
		  end
	       end, fsm, rfsm.is_trans)

   local function check_act_timeevents(fsm)
      local function check_timeevent(fsm, sta)
	 if sta._check_timeevent then sta._check_timeevent() end
      end
      rfsm.map_from_to(fsm, check_timeevent, fsm._act_leaf, fsm)
   end

   rfsm.post_step_hook_add(fsm, check_act_timeevents)
end

rfsm.preproc[#rfsm.preproc+1] = expand_timeevent

return M