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
  local axis, direction = value:match '(.+)%s*([%+%-])'
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

function Player:_updateControls(controls)
  for name, sources in pairs(controls.inputs) do
    if not self.inputs[name] then
      self.inputs[name] = {value = 0}
    end
    local input = self.inputs[name]
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
  for name, inputs in pairs(controls.axes) do
    self.axes[name] = {
      value = 0,
      inputs = inputs,
    }
  end
  for name, axes in pairs(controls.pairs) do
    self.pairs[name] = {
      value = 0,
      axes = axes,
    }
  end
end

function Player:_updateInput(input)
  input._binary = 0
  for i = 1, #input._binarySources do
    if input._binarySources[i](self) == 1 then
      input._binary = 1
      break
    end
  end

  input._analog = 0
  for i = 1, #input._analogSources do
    input._analog = input._analog + input._analogSources[i](self)
  end
  if input._analog > 1 then input._analog = 1 end

  local v = math.max(input._binary, input._analog)
  input._value = v > self.deadzone and v or 0
end

function Player:_updateAxis(axis)
  local n = self.inputs[axis.inputs.negative]
  local p = self.inputs[axis.inputs.positive]
  axis._binary = p._binary - n._binary
  axis._analog = p._analog - n._analog
  if axis._binary == 0 then
    axis._value = math.abs(axis._analog) > self.deadzone and axis._analog or 0
  else
    axis._value = axis._binary
  end
end

function Player:_updatePair(pair)
  local x = self.axes[pair.axes.x]
  local y = self.axes[pair.axes.y]
  if x._binary == 0 and y._binary == 0 then
    local value = {x = x._analog, y = y._analog}
    local length = (value.x^2 + value.y^2)^.5
    pair._value = length > self.deadzone and value or {x = 0, y = 0}
  else
    pair._value = {x = x._binary, y = y._binary}
  end
  local length = (pair._value.x^2 + pair._value.y^2)^.5
  if length > 1 then
    pair._value.x = pair._value.x / length
    pair._value.y = pair._value.y / length
  end
end

function Player:update()
  for _, input in pairs(self.inputs) do
    self:_updateInput(input)
  end
  for _, axis in pairs(self.axes) do
    self:_updateAxis(axis)
  end
  for _, pair in pairs(self.pairs) do
    self:_updatePair(pair)
  end
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

function Player:_init(controls, joystick)
  self.inputs = {}
  self.axes = {}
  self.pairs = {}
  self.joystick = joystick
  self.deadzone = .5
  self:_updateControls(controls)
end

function baton.newPlayer(...)
  local player = setmetatable({}, {__index = Player})
  player:_init(...)
  return player
end

return baton
