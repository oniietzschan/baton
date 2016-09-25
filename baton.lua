local baton = {}

local source = {}

local Player = {}

function Player:_updateControls(controls)
  for name, sources in pairs(controls.inputs) do
    self.inputs[name] = {sources = sources}
  end
end

--function Player:update()
--  for _, input in pairs(self.inputs) do
--    local v = input.get(self)
--    input.value = v > self.deadzone and v or 0
--  end
--end

function Player:get(name)
  if self.inputs[name] then
    local s = self.inputs[name].sources

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
        return 1
      end

      -- TODO: figure out what should happen if multiple axes are mapped
      -- to one control (or if that should even be allowed)
      if s.axes then
        local axis, direction = s.axes[1]:match('(.*)(.)')
        if direction == '+' then direction = 1 end
        if direction == '-' then direction = -1 end
        local value = self.joystick:getGamepadAxis(axis)
        value = value * direction
        if value > self.deadzone then return value end
      end
    end
    return 0
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
