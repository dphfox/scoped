# scoped

Defeat subtly-leaky code with rigour. `scoped` innovates where the maid pattern left off, with a first-principles simple design that turns best practices into enforced rules through syntax design and static typing.


## Cleanup tables

Maids mostly just store a list of things to clean up, underneath an OOP abstraction layer. Their only truly unique method is `:destroy()` which contains the cleanup logic.

```Lua
local maid = Maid()

maid:add(Person("Sally"))
maid:add(Person("Bob"))
maid:add(Person("Mortimer"))

maid:destroy()
```

`scoped` ditches the OOP for a plain 'cleanup table'. The cleanup logic moves into a standalone function call.

```Lua
local scope = {}

table.insert(scope, Person("Sally"))
table.insert(scope, Person("Bob"))
table.insert(scope, Person("Mortimer"))

doCleanup(scope)
```

This trims weight, and doesn't sacrifice functionality other than one or two syntax conveniences. The standalone function is advantageous as it is more reusable, including as a callback passed into other function calls.

## Constructors

Traditionally, objects have `:destroy()` methods to clean themselves up. This is how Luau users typically limit the lifetime of an object.

```Lua
local function Person(name)
    local self = {
        name = name,
        destroy = function()
            print(name, "left the building!")
        end
    }
    return self
end
```

While these methods are simple in theory, they are invisible at the call site, and there is no clear indication or naming convention that indicates the lifetime of the object should be considered at all.

```Lua
-- these objects are never destroyed, but it doesn't error and doesn't look suspicious
local sally = Person("Sally")
local bob = Person("Bob")
local mortimer = Person("Mortimer")
```

`scoped` adopts a new convention for constructors; the first parameter is always a cleanup table, no exceptions. Objects add their cleanup tasks to the table.

```Lua
local function Person(cleanup, name)
    local self = {
        name = name
    }
    table.insert(cleanup, function()
        print(name, "left the building!")
    end)
    return self
end
```

This convention forces users to provide a cleanup table, which means they are forced to consider the lifetime of the object. Incorrect code becomes obvious and statically checkable.

```Lua
local scope = {}

-- Failing to include a cleanup table is now an obvious type error
local sally = Person(scope, "Sally")
local bob = Person(scope, "Bob")
local mortimer = Person(scope, "Mortimer")

doCleanup(scope)
```

As a free bonus, using the first parameter for cleanup information allows especially readable syntax using the `scoped` method. It creates a blank cleanup table, then points the metatable's `__index` at whatever constructors you wish to use. This keeps the arguments list clean and plays better with curried constructors and constructors using literal call syntax.

```Lua
local scope = scoped(constructors)

local sally = scope:Person("Sally")
local bob = scope:Person("Bob")
local mortimer = scope:Person("Mortimer")

doCleanup(scope)
```
