local baton = {}

local source = {}

local Player = {}

function Player:_updateControls(controls)
  for name, sources in pairs(controls.inputs) do
    self.inputs[name] = {
      value = 0,
      sources = sources,
    }
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

function Player:_getBinarySources(s)
  if s.keys and love.keyboard.isDown(unpack(s.keys)) then
    return 1
  end
  if s.scancodes and love.keyboard.isScancodeDown(unpack(s.scancodes)) then
    return 1
  end
  if s.mouseButtons and love.mouse.isDown(unpack(s.mouseButtons)) then
    return 1
  end
  if self.joystick then
    if s.buttons and self.joystick:isGamepadDown(unpack(s.buttons)) then
      input._binary = 1
    end
  end
  return 0
end

function Player:_getAnalogSources(s)
  if self.joystick then
    -- TODO: figure out what should happen if multiple axes are mapped
    -- to one control (or if that should even be allowed)
    if s.axes then
      local axis, direction = s.axes[1]:match('(.*)(.)')
      if direction == '+' then direction = 1 end
      if direction == '-' then direction = -1 end
      local value = self.joystick:getGamepadAxis(axis)
      value = value * direction
      if value > 0 then return value end
    end
  end
  return 0
end

function Player:_updateInput(input)
  input._binary = self:_getBinarySources(input.sources)
  input._analog = self:_getAnalogSources(input.sources)
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
