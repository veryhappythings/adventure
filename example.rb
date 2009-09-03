require 'adventure'

class Key < Item
  def initialize
    @name = 'key'
    @description = 'a rusty iron key'
  end
end

Location.new do
  label :room
  name 'The first room'
  desc 'You are in a boring stone room.'
  exit :direction => :north, :target => :second_room, :description => 'A door is set in the stone to the North.'
  item Key.new
end

Location.new do
  label :second_room
  exit :direction => :south, :target => :room
  exit :direction => :east, :target => :end_room
end

Location.new do
  label :end_room

  on_entrance do
    Game.exit_game
    puts 'You have completed the game! Thanks for playing.'
    false
  end
end

game = Game.new(Player.new, :room)
game.play
