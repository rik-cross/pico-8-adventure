pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cls()
print('hello!')

player = {
 name = 'rik',
 score = 100
}
print('name is ' .. player['name'])

player.health = 75
print('health is ' .. player.health)

player.status = function()
 print(player.name)
 print('score ' .. player.score)
 print('health ' .. player.health)
end

print('\n')
player.status()

