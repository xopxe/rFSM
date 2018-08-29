--
-- composite tests transitions
--

package.path = package.path .. ';../?.lua'

local rfsm = require "rfsm"
local rfsm2tree = require "rfsm2tree"
local rfsm_testing = require "rfsm_testing"
local rfsmpp = require "rfsmpp"
local utils = require "utils"


local function puts(...)
   return function () print(unpack(arg)) end
end

local testfsm = rfsm.load("../examples/composite_exitconn.lua")
testfsm.dbg = false

local test = {
   id = 'composite_exitconn',
   pics = false,
   tests = {
      {
	 descr='testing entry',
	 preact = nil,
	 events = nil,
	 expect = { leaf='root.idle', mode='done' },
      }, {
	 descr='testing exit connector',
	 events = { 'e_start' },
	 expect = { leaf='root.recharging', mode='done'},
      }
   }
}


local fsm = rfsm.init(testfsm, "composite_exitconn")

rfsm_testing.print_stats(rfsm_testing.test_fsm(fsm, test, false))
