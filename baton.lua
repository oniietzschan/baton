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
  if n._binary == 0 and p._binary == 0 then
    local v = p._analog - n._analog
    axis._value = math.abs(v) > self.deadzone and v or 0
  else
    axis._value = p._binary - n._binary
  end
end

function Player:update()
  for _, input in pairs(self.inputs) do
    self:_updateInput(input)
  end
  for _, axis in pairs(self.axes) do
    self:_updateAxis(axis)
  end
end

function Player:get(name)
  if self.axes[name] then
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
