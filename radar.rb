require 'json'
require './lib/simulate_helper'

values = CLI.new

values.add_arg("sport", ARGV[0])
values.add_arg("year",  ARGV[1].to_i)

sport = values.args["sport"]
year   = values.args["year"]

radar = Radar.new(sport, year)
  
radar.get_schedule
radar.get_games
radar.save_games
