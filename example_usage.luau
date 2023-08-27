--!strict
local scoped = require("./scoped.luau")
local scoped, doCleanup = scoped.scoped, scoped.doCleanup

local constructors = {}

function constructors.Person(
	cleanup: scoped.CleanupTable,
	name: string 
)
	local self = {
		name = name
	}
	table.insert(cleanup, function()
		print(name, "has left the building!")
	end)
	return self
end

local scope = scoped(constructors)

local sally = scope:Person("Sally")
local bob = scope:Person("Bob")
local mortimer = scope:Person("Mortimer")
local geoff = scope:Person("Geoff")

doCleanup(scope)
