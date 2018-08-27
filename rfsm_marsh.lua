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

local rfsm = require ("rfsm")
local utils = require ("utils")
local pcall = pcall
local tostring = tostring
local print = print -- debugging only

--module("rfsm_marsh")
local M ={}

-- shortcuts
local mapfsm = rfsm.mapfsm
local get_sta_mode = rfsm.get_sta_mode
local is_composite = rfsm.is_composite
local is_leaf = rfsm.is_leaf
local is_conn = rfsm.is_conn
local is_node = rfsm.is_node
local is_trans = rfsm.is_trans

--- Convert an initalized fsm to a table
function M.model2tab(fsm)
   --- convert a transition to a table
   -- @param t rfsm.transition
   local function trans2tab(t)
      --- safely convert an event to a string
      -- @param e arbitrary event type that supports __tostring
      local function ev2str(e)
	 local res, evstr = pcall(tostring, e)
	 if res then return evstr
	 else return "?" end
      end
      return { type='transition', src=t.src._fqn, tgt=t.tgt._fqn,
	       pn=t.pn, events=utils.imap(ev2str, t.events) }
   end

   --- convert (sub-) fsm s to a table
   local function __rfsm2tab(s)
      if is_leaf(s) then
	 return { id=s._id, type='state' }
      elseif is_conn(s) then
	 return { id=s._id, type='connector' }
      elseif is_composite(s) then
	 local tab = { id=s._id, type='state' }
	 tab.transitions = mapfsm(trans2tab, s, is_trans, 1)
	 tab.subnodes = mapfsm(__rfsm2tab, s, rfsm.is_nr_node, 1)
	 return tab
      end
   end

   if not fsm._initialized then
      error("rfsm2tab: initialized fsm required")
      return false
   end

   return __rfsm2tab(fsm)
end

--- Return the active state of an rFSM.
-- @return active leaf state fqn
-- @return state of that fqn
-- @return transition path taken to last state
function M.actinfo2tab(fsm)
   if fsm._act_leaf then
      return fsm._act_leaf._fqn, get_sta_mode(fsm._act_leaf), false
   end
   return false, false, false
end

return M