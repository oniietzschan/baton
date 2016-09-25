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

function Player:_calculateInput(input)
  input._binary = self:_getBinarySources(input.sources)
  input._analog = self:_getAnalogSources(input.sources)
  local v = math.max(input._binary, input._analog)
  input._value = v > self.deadzone and v or 0
end

function Player:update()
  for _, input in pairs(self.inputs) do
    self:_calculateInput(input)
  end
end

function Player:get(name)
  if self.inputs[name] then return self.inputs[name]._value end
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
