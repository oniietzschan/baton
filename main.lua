local baton = require 'baton'

controls = {
  inputs = {
    left = {'key:left', 'axis:leftx-'},
    right = {'key:right', 'axis:leftx+'},
    up = {'key:up', 'axis:lefty-'},
    down = {'key:down', 'axis:lefty+'},
  },
  axes = {
    horizontal = {negative = 'left', positive = 'right'},
    vertical = {negative = 'up', positive = 'down'},
  },
  pairs = {
    main = {x = 'horizontal', y = 'vertical'},
  }
}

function love.load()
  input = baton.newPlayer(controls, love.joystick.getJoysticks()[1])
end

function love.update()
  input:update()
  for _, name in pairs {'left', 'right', 'up', 'down'} do
    if input:pressed(name) then
      print('pressed: ' .. name)
    end
    if input:released(name) then
      print('released: ' .. name)
    end
  end
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end

function love.draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.line(0, 300, 800, 300)
  love.graphics.line(400, 0, 400, 600)
  love.graphics.rectangle('line', 200, 100, 400, 400)
  love.graphics.rectangle('line', 300, 200, 200, 200)
  love.graphics.circle('line', 400, 300, 100)
  love.graphics.circle('line', 400, 300, 200)

  love.graphics.setColor(84, 214, 227)
  love.graphics.circle('fill', 400 - 200*input:get 'left', 300, 8)
  love.graphics.circle('fill', 400 + 200*input:get 'right', 300, 8)
  love.graphics.circle('fill', 400, 300 - 200*input:get 'up', 8)
  love.graphics.circle('fill', 400, 300 + 200*input:get 'down', 8)

  love.graphics.setColor(207, 205, 74)
  love.graphics.circle('fill', 400 + 200*input:get 'horizontal', 300, 8)
  love.graphics.circle('fill', 400, 300 + 200*input:get 'vertical', 8)

  love.graphics.setColor(205, 92, 204)
  x, y = input:get 'main'
  love.graphics.circle('fill', 400 + 200*x, 300 + 200*y, 8)
end
