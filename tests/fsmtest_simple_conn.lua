--
-- test simple transitions
--

package.path = package.path .. ';../?.lua'

local rfsm = require "rfsm"
local rfsm2tree = require "rfsm2tree"
local rfsm2uml = require("rfsm2uml")
local rfsm_testing = require "rfsm_testing"
local rfsmpp = require "rfsmpp"
local utils = require "utils"


local testfsm = rfsm.load("../examples/connector_simple.lua")
testfsm.dbg=false

local test = {
   id = 'simple_conn_test',
   pics = true,
   tests = {
      { descr = 'testing entry',
	preact = nil,
	events = nil,
	expect = { leaf='root.start', mode='done' }, },

      { descr = 'testing failed connector transition 1',
	preact = nil,
	events = { "some_event" } ,
	expect = { leaf='root.start', mode='done' }, },

      { descr = 'testing failed connector transition 2',
	preact = nil,
	events = { "eventA" },
	expect = { leaf='root.start', mode='done' }, },

      { descr = 'testing successfull connector transition',
	preact = nil,
	events = { "eventA", "eventB" },
	expect = { leaf='root.end', mode='done' }, },
   }
}

local jc = rfsm.init(testfsm)

if not jc then
   err(test.id .. " initalization failed")
   os.exit(1)
end

rfsm_testing.print_stats(rfsm_testing.test_fsm(jc, test, false))
