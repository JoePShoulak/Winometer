require './lib/simulate_helper'

if ARGV.empty?
  puts "Needs arguments"
  puts "simulate.rb SPORT YEAR PERIODS(/ALL) (VERBOSE)"
  exit
end

values = CLI.new

values.add_arg("sport", ARGV[0])
values.add_arg("year",  ARGV[1].to_i)
values.add_arg("periods", ARGV[2])
values.change_arg("periods", values.args["periods"].to_i) if values.args["periods"].to_i.to_s == values.args["periods"]
values.add_arg("verbose", ARGV[3])
values.change_arg("verbose", values.args["verbose"] == "true")

sport   = values.args["sport"]
year    = values.args["year"]
periods = values.args["periods"]
verbose = values.args["verbose"]

s = Simulation.new(sport, year, periods, verbose)

s.run
