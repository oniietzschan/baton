local baton = require 'baton'

controls = {
  inputs = {
    moveLeft = {scancodes = {'a'}, axes = {'leftx-'}},
    moveRight = {scancodes = {'d'}, axes = {'leftx+'}},
    moveUp = {scancodes = {'w'}, axes = {'lefty-'}},
    moveDown = {scancodes = {'s'}, axes = {'lefty+'}},
    aimLeft = {keys = {'left'}, axes = {'rightx-'}},
    aimRight = {keys = {'right'}, axes = {'rightx+'}},
    aimUp = {keys = {'up'}, axes = {'righty-'}},
    aimDown = {keys = {'down'}, axes = {'righty+'}},
  },
  axes = {
    moveX = {'moveLeft', 'moveRight'},
    moveY = {'moveUp', 'moveDown'},
    aimX = {'aimLeft', 'aimRight'},
    aimY = {'aimUp', 'aimDown'},
  },
  pairs = {
    move = {'moveX', 'moveY'},
    aim = {'aimX', 'aimY'}
  }
}

function love.load()
  input = baton.newPlayer(controls, love.joystick.getJoysticks()[1])
end

function love.update()
  input:update()
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end

function love.draw()
  love.graphics.print(input:get 'moveLeft', 0, 0)
  love.graphics.print(input:get 'moveRight', 0, 16)
end
