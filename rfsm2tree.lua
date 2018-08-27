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

local gv = require('gv')
local rfsm = require('rfsm')
local utils = require('utils')

local pairs, ipairs, print, table, string, type, assert, io
   = pairs, ipairs, print, table, string, type, assert, io

--module("rfsm2tree")
local M= {}

local param = {}
M.param = param

param.trfontsize = 7.0
param.show_fqn = false
param.and_color="green"
param.and_style="dashed"
param.hedge_color="blue"
param.hedge_style="dotted"

param.layout="dot"
param.err=print
param.dbg = function () return true end

-- overall state properties

local function set_sprops(nh)
   gv.setv(nh, "style", "rounded")
   gv.setv(nh, "shape", "box")
end

local function set_ini_sprops(nh)
   gv.setv(nh, "shape", "point")
   gv.setv(nh, "height", "0.15")
end

local function set_fini_sprops(nh)
   gv.setv(nh, "shape", "doublecircle")
   gv.setv(nh, "label", "")
   gv.setv(nh, "height", "0.1")
end

local function set_hier_trans_props(eh)
   gv.setv(eh, "arrowhead", "none")
   gv.setv(eh, "style", param.hedge_style)
   gv.setv(eh, "color", param.hedge_color)
end

local function set_trans_props(eh)
   gv.setv(eh, "fontsize", param.trfontsize)
end

-- create new graph and add root node
local function new_graph(fsm)
   local gh = gv.digraph("hierarchical chart: " .. fsm._id)
   gv.setv(gh, "rankdir", "TD")

   local nh = gv.node(gh, fsm._fqn)
   set_sprops(nh)

   return gh
end

-- add regular type of state
local function add_state(gh, parent, state)

   local nh = gv.node(gh, state._fqn)
   set_sprops(nh)

   local eh = gv.edge(gh, parent._fqn, state._fqn)
   set_hier_trans_props(eh)

   if not param.show_fqn then
      gv.setv(nh, "label", state._id)
   end
end

-- add initial states
local function add_ini_state(gh, tr, parent)
   local nh, eh
   if tr.src._id == 'initial' then
      nh = gv.node(gh, parent._fqn .. '.initial')
      set_ini_sprops(nh)
      eh = gv.edge(gh, parent._fqn, parent._fqn .. '.initial')
      set_hier_trans_props(eh)
   end
end

-- add  final states
local function add_fini_state(gh, tr, parent)
   local nh, eh
   if tr.tgt._id == 'final' then
      nh = gv.node(gh, parent._fqn .. '.final')
      set_fini_sprops(nh)
      eh = gv.edge(gh, parent._fqn, parent._fqn .. '.final')
      set_hier_trans_props(eh)
   end
end


-- add a transition from src to tgt
local function add_trans(gh, tr, parent)
   local src, tgt, eh

   if tr.src == 'initial' then src = parent._fqn .. '.initial'
   else src = tr.src._fqn end

   if tr.tgt == 'final' then tgt = parent._fqn .. '.final'
   else tgt = tr.tgt._fqn end

   eh = gv.edge(gh, src, tgt)
   gv.setv(eh, "constraint", "false")
   if tr.events then gv.setv(eh, "label", table.concat(tr.events, ', ')) end
   set_trans_props(eh)
end

local function fsm2gh(fsm)
   local gh = new_graph(fsm)
   rfsm.mapfsm(function (tr, p) add_ini_state(gh, tr, p) end, fsm, rfsm.is_trans)
   rfsm.mapfsm(function (s) add_state(gh, s._parent, s) end, fsm, rfsm.is_state)
   rfsm.mapfsm(function (tr, p) add_fini_state(gh, tr, p) end, fsm, rfsm.is_trans)

   rfsm.mapfsm(function (tr, p) add_trans(gh, tr, p) end, fsm, rfsm.is_trans)
   return gh
end


-- convert fsm to
function M.rfsm2tree(fsm, format, outfile)

   if not fsm._initialized then
      param.err("rfsm2tree ERROR: fsm " .. (fsm._id or 'root') .. " uninitialized")
      return false
   end

   local gh = fsm2gh(fsm)
   gv.layout(gh, param.layout)
   param.dbg("rfsm2tree: running " .. param.layout .. " layouter")
   gv.render(gh, format, outfile)
   param.dbg("rfsm2tree: rendering to " .. format .. ", written result to " .. outfile)
end

return M