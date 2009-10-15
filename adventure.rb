require 'rubygems'
require 'metaid'
# TODO locked doors
# TODO enemies
# TODO NPCs.
# TODO skills/levels/experience
# Is it possible to extend location?

class Item
  def initialize
    @name = ''
    @description = ''
  end

  def describe
    @description
  end

  def use
    false
  end

  attr_reader :name
end


class Exit
  def initialize(description, target)
    @description = description
    @target = target
  end

  def describe
    @description
  end

  attr_reader :target
end

class LocationAttributes
  def initialize(&block)
    @attributes = {:exits => {}}
    @scripted_scenes = {}
    @inventory = []
    instance_eval &block
  end

  def self.text_attributes(*attrs)
    attrs.each do |attr|
      define_method attr do |text|
        @attributes[attr] = text
      end
    end
  end

  def self.scripted_scenes(*attrs)
    attrs.each do |attr|
      define_method attr do |&block|
        @scripted_scenes[attr] = block
      end
    end
  end

  def item(obj)
    @inventory << obj
  end

  def exit(args)
    @attributes[:exits][args[:direction]] = Exit.new(args[:description], args[:target])
  end

  text_attributes :label, :name, :desc
  scripted_scenes :on_entrance
  attr_reader :attributes, :scripted_scenes, :inventory
end

class Location
  @pool = {}
  class << self; attr_accessor :pool; end

  def self.get(sym)
    @pool[sym]
  end

  def initialize(&block)
    location_attributes = LocationAttributes.new(&block)
    location_attributes.attributes.each do |key, value|
      instance_variable_set(:"@#{key}", value)
      meta_eval do
        attr_reader :"#{key}"
      end
    end

    location_attributes.scripted_scenes.each do |key, value|
      meta_def key, &value
    end

    @inventory = location_attributes.inventory

    if @label
      self.class.pool[@label] = self
    end
  end

  def add_exit!(args)
    @exits[args[:direction]] = Exit.new(args[:description], args[:target])
  end

  def to_s
    "#{@name} - #{@desc} - #{@exits.keys}"
  end

  def no_exit?
    @exits.length == 0
  end

  def describe
    description = []
    description << desc if respond_to? :desc

    if no_exit?
      description << 'There appears to be no way out.'
    else
      @exits.each do |direction, exit|
        if exit.describe
          description << exit.describe
        else
          description << "There is an exit to the #{direction}."
        end
      end
    end

    if @inventory.length > 0
      description << 'You can see:'
      @inventory.each do |item|
        description << item.describe
      end
    end

    description
  end

  def take(item)
    collected_item = item
    if item.class != Item
      collected_item = @inventory.find {|inventory_item| inventory_item.name == item}
    end
    if collected_item
      @inventory.delete(collected_item)
    end
    collected_item
  end

  attr_reader :inventory
end

class Player
  def initialize()
    @current_location = nil
    @inventory = []
    @actions = [:look, :move, :get, :use]
  end

  def teleport(location)
    location = Location.get(location) if location.class == Symbol
    @current_location = location
  end

  def get!(item_name)
    if collected_item = @current_location.take(item_name)
      puts "You picked up the #{collected_item.name}"
      @inventory << collected_item
    else
      puts "I cannot see a #{item_name}"
    end
  end

  def look
    puts @current_location.describe
  end

  def move!(direction)
    if @current_location.exits[direction.to_sym]
      @current_location = Location.get(@current_location.exits[direction.to_sym].target)
      if Game.hook @current_location, :on_entrance
        look
      end
    else
      puts 'I can\'t move that way.'
    end
  end

  def owns?(item_name)
    @inventory.find {|item| item.name == item_name}
  end

  def use!(item_name)
    if item = owns?(item_name)
        if !item.use
          @current_location.inventory.each do |location_item|
            if item.use_on(location_item)
              look
              return
            end
          end
        end
    else
      puts "You do not have a #{item_name}"
    end
  end

  def act(command)
    command = command.split(/\s/)
    case command[0]
      when /^l/
        look
      when /^m/
        move! command[1]
      when /^g/
        get! command[1]
      when /^u/
        use! command[1]
      when /^help/
        puts @actions
      else
        puts "I do not understand the command '#{command[0]}'"
    end
  end
end

class Game
  @playing = true
  class << self; attr_accessor :playing; end

  def self.exit_game
    Game.playing = false
  end

  def self.hook(location, hook_name)
    if location.respond_to? hook_name
      location.send hook_name
    else
      true
    end
  end

  def initialize(player, starting_location)
    @player = player
    @starting_location = Location.get(starting_location)
  end

  def play
    @player.teleport @starting_location
    @player.act('look')
    while Game.playing
      print '? '
      command = gets.strip
      if command == 'q'
        Game.playing = false
      else
        @player.act(command)
      end
    end
  end
end