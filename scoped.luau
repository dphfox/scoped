--!strict
-- (c) Daniel P H Fox 2023. Licensed under MIT, you must attribute when using.
-- scoped 0.1.0 - https://github.com/dphfox/scoped

local scoped = {}

-- Types that will be processed by `doCleanup`.
export type Cleanable =
	Instance 
	| RBXScriptConnection
	| () -> ()
	| CleanableObjectLower
	| CleanableObjectUpper
	| CleanupTable

type CleanableObjectLower = {
	destroy: (CleanableObjectLower) -> ()
}

type CleanableObjectUpper = {
	Destroy: (CleanableObjectUpper) -> ()
}

-- Cleanup tables are an array of cleanable types.
export type CleanupTable = {Cleanable}

-- Constructors must always start with a cleanup table parameter.
export type Constructor<R, A...> = (CleanupTable, A...) -> R

-- Constructor tables are used for `scoped()` syntax.
export type ConstructorTable = {[string]: Constructor<any, any>}

-- Non-variadic form of `doCleanup`.
local function doCleanupOne(task: any)
	local taskType = typeof(task)

	if taskType == "Instance" then
		task:Destroy()

	elseif taskType == "RBXScriptConnection" then
		task:Disconnect()

	elseif taskType == "function" then
		task()

	elseif taskType == "table" then
		if typeof(task.destroy) == "function" then
			task:destroy()

		elseif typeof(task.Destroy) == "function" then
			task:Destroy()

		elseif task[1] ~= nil then
			for _, subtask in ipairs(task) do
				doCleanupOne(subtask)
			end
		end
	end
end

-- Cleans up all of its arguments:
-- - Instances will be `:Destroy()`-ed
-- - RBXScriptConnections will be `:Disconnect()`-ed
-- - functions will be invoked
-- - objects with `:destroy()` or `:Destroy()` methods will be called
-- - cleanup tables will be iterated over, the values will be cleaned up
-- - other types are no-ops
function scoped.doCleanup(...: any)
	for index = 1, select("#", ...) do
		doCleanupOne(select(index, ...))
	end
end

-- Creates a cleanup table that allows construction of objects from the given
-- tables using method call notation. Constructors from tables specified later
-- will override identically-named constructors from tables specified earlier.
function scoped.scoped<T>(...: T & ConstructorTable): CleanupTable & T
	-- TODO: The return type annotation only works for single arguments.
	-- How should it be done for a variadic number?
	local merged = {}
	-- Luau does not like the type of this parameter in this for loop.
	for name, func in ... :: any do
		merged[name] = func
	end
	-- Lying about the return type technically.
	return setmetatable({}, {__index = merged}) :: any
end

return scoped