require 'adventure'

class Key < Item
  def initialize
    @name = 'key'
    @description = 'a rusty iron key'
  end

  def use_on(other_item)
    if other_item.class == Door
      puts 'The key fits into the lock.'
      other_item.open
      true
    else
      false
    end
  end
end

class Door < Item
  def initialize(location)
    @name = 'door'
    @description = 'a rusty iron door'
    @location = location
  end

  def open
    @location = Location.get(@location) if @location.class == Symbol
    @location.add_exit!(:direction => :east, :target => :end_room, :description => 'There is an open door to the East.')
    @location.take(@name)
    puts 'The door creaks open.'
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
  item Door.new(:second_room) # FIXME: shouldn't have to pass in this label
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
