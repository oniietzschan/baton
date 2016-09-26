local function length(x, y)
  return (x^2 + y^2)^.5
end

local function trim(x, y, max)
  local l = length(x, y)
  if l > max then
    x = x / l
    y = y / l
  end
  return x, y
end



local baton = {}



local sourceFunction = {}

function sourceFunction.key(key)
  return function()
    return love.keyboard.isDown(key) and 1 or 0
  end
end

function sourceFunction.sc(scancode)
  return function()
    return love.keyboard.isScancodeDown(scancode) and 1 or 0
  end
end

function sourceFunction.mouse(button)
  return function()
    return love.mouse.isDown(tonumber(button)) and 1 or 0
  end
end

function sourceFunction.axis(value)
  local axis, direction = value:match '(.+)([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function(self)
    if self.joystick then
      local v = tonumber(axis) and self.joystick:getAxis(tonumber(axis))
                                or self.joystick:getGamepadAxis(axis)
      v = v * direction
      return v > 0 and v or 0
    end
    return 0
  end
end

function sourceFunction.button(button)
  return function(self)
    if self.joystick then
      if tonumber(button) then
        return self.joystick:isDown(tonumber(button)) and 1 or 0
      else
        return self.joystick:isGamepadDown(button) and 1 or 0
      end
    end
    return 0
  end
end



local Player = {}

-- implementation functions

function Player:_init(controls, joystick)
  self.inputs = {}
  self.axes = {}
  self.pairs = {}
  self.joystick = joystick
  self.deadzone = .5
  self:_updateControls(controls)
end

local function addSources(input, sources)
  input._binarySources = {}
  input._analogSources = {}
  for i = 1, #sources do
    local source = sources[i]
    local type, value = source:match '(.*):(.*)'
    assert(sourceFunction[type], type .. 'is not a valid input source')
    if type == 'axis' then
      table.insert(input._analogSources, sourceFunction[type](value))
    else
      table.insert(input._binarySources, sourceFunction[type](value))
    end
  end
end

function Player:_updateControls(controls)
  for name, sources in pairs(controls.inputs) do
    if not self.inputs[name] then
      self.inputs[name] = {value = 0}
    end
    addSources(self.inputs[name], sources)
  end
  for name, inputs in pairs(controls.axes) do
    if not self.axes[name] then
      self.axes[name] = {value = 0}
    end
    self.axes[name].inputs = inputs
  end
  for name, axes in pairs(controls.pairs) do
    if not self.pairs[name] then
      self.pairs[name] = {value = 0}
    end
    self.pairs[name].axes = axes
  end
end

function Player:_getBinarySources(input)
  for i = 1, #input._binarySources do
    if input._binarySources[i](self) == 1 then
      return 1
    end
  end
  return 0
end

function Player:_getAnalogSources(input)
  local v = 0
  for i = 1, #input._analogSources do
    v = v + input._analogSources[i](self)
  end
  if v > 1 then v = 1 end
  return v
end

function Player:_processInput(input)
  input._binary = self:_getBinarySources(input)
  input._analog = self:_getAnalogSources(input)
  local v = math.max(input._binary, input._analog)
  input._value = v > self.deadzone and v or 0
end

function Player:_processAxis(axis)
  local n = self.inputs[axis.inputs.negative]
  local p = self.inputs[axis.inputs.positive]
  axis._usingBinary = n._binary == 1 or p._binary == 1
  axis._binary = p._binary - n._binary
  axis._analog = p._analog - n._analog
  if axis._usingBinary then
    axis._value = axis._binary
  else
    axis._value = math.abs(axis._analog) > self.deadzone and axis._analog or 0
  end
end

function Player:_processPair(pair)
  local x = self.axes[pair.axes.x]
  local y = self.axes[pair.axes.y]
  if x._usingBinary or y._usingBinary then
    pair._value = {x = x._binary, y = y._binary}
  else
    local v = {x = x._analog, y = y._analog}
    pair._value = length(v.x, v.y) > self.deadzone and v or {x = 0, y = 0}
  end
  pair._value.x, pair._value.y = trim(pair._value.x, pair._value.y, 1)
end

--public API

function Player:update()
  for _, input in pairs(self.inputs) do self:_processInput(input) end
  for _, axis in pairs(self.axes) do self:_processAxis(axis) end
  for _, pair in pairs(self.pairs) do self:_processPair(pair) end
end

function Player:get(name)
  if self.pairs[name] then
    return self.pairs[name]._value.x, self.pairs[name]._value.y
  elseif self.axes[name] then
    return self.axes[name]._value
  elseif self.inputs[name] then
    return self.inputs[name]._value
  end
  assert(false, 'No input, axis, or pair found with name ' .. name)
end

function baton.newPlayer(...)
  local player = setmetatable({}, {__index = Player})
  player:_init(...)
  return player
end



return baton
