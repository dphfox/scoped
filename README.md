# scoped
### Version 0.1.0
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

Traditionally, constructors insert `:destroy()` methods for cleaning objects up. This is how Luau users typically limit the lifetime of an object.

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

`scoped` adopts a new convention for constructors; the first parameter is always a cleanup table, no exceptions. Objects add themselves to the cleanup table.

```Lua
local function Person(cleanup, name)
    local self = {
        name = name
        destroy = function()
            print(name, "left the building!")
        end
    }
    table.insert(cleanup, self)
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

Using the first parameter for cleanup information allows especially readable syntax using the `scoped` function. It creates a blank cleanup table, then points the metatable's `__index` at whatever constructors you wish to use. This keeps the arguments list clean and plays better with curried constructors and constructors using literal call syntax.

```Lua
local constructors = { Person = Person } -- try pointing at your favourite library
local scope = scoped(constructors)

local sally = scope:Person("Sally")
local bob = scope:Person("Bob")
local mortimer = scope:Person("Mortimer")

doCleanup(scope)
```

## Example snippet (Fusion)

```Lua
local function Button(props: Props)
    local scope = scoped(Fusion)
    
    local animColoured = scope:Spring(scope:Computed(function(use)
        return if use(props.Coloured) then 1 else 0
    end), 50)
    
    local isHovering = scope:Value(false)
    local isPressed = scope:Value(false)
    
    local textColour = scope:Computed(function(use)
        local isDark = isColourDark(use(props.Colour)) 
        local atopColour = if isDark then use(Theme.textAtopDark) else use(Theme.textAtopLight)
        return use(Theme.text):Lerp(atopColour, use(animColoured))
    end)
    
    return scope:New "ImageButton" {
        [Cleanup] = scope,
        
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        LayoutOrder = props.LayoutOrder,
        ZIndex = props.ZIndex,
        Size = props.Size,
        AutomaticSize = props.AutomaticSize,
        Visible = props.Visible,
        
        Active = scope:Computed(function(use)
            return not use(props.Disabled)
        end),
        BackgroundColor3 = scope:Computed(function(use)
            return use(Theme.lightenColour):Lerp(use(props.Colour), use(animColoured))
        end),
        BackgroundTransparency = scope:Computed(function(use)
            return use(Theme.lighten1) * (1 - use(animColoured))
        end),
        
        [Styles.text.Send] = textColour,
        
        [OnEvent "Activated"] = props.OnClick,
        
        [OnEvent "MouseEnter"] = function()
            isHovering:set(true)
        end,
        [OnEvent "MouseLeave"] = function()
            isHovering:set(false)
            isPressed:set(false)
        end,
        [OnEvent "MouseButton1Down"] = function()
            isPressed:set(true)
        end,
        [OnEvent "MouseButton1Up"] = function()
            isPressed:set(false)
        end,
        
        [Children] = {
            Round(4),
            scope:New "Frame" {
                BackgroundTransparency = scope:Spring(scope:Computed(function(use)
                    return if use(isPressed) then 0.75 else 1
                end), 50),
                BackgroundColor3 = Color3.new(0, 0, 0),
                Size = UDim2.fromScale(1, 1),
                
                [Children] = {
                    Round(4),
                    Padding(1),
                    scope:New "Frame" {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),

                        [Children] = {
                            Round(2),
                            Padding(3),
                            scope:New "UIStroke" {
                                Thickness = 1,
                                Color = textColour,
                                Transparency = scope:Spring(scope:Computed(function(use)
                                    return if use(isHovering) then 0.75 else 1
                                end), 50)
                            },
                            props[Children]
                        }
                    }
                }
            }
        }
    }
end
```

## License

Licensed the same way as all of my open source projects: BSD 3-Clause + Security Disclaimer.

As with all other projects, you accept responsibility for choosing and using this project.

See [LICENSE](./LICENSE) or [the license summary](https://github.com/dphfox/licence) for details.
