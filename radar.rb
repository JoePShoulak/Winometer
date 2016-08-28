require 'json'
require './lib/simulate_helper'

def get_schedule(sport, year)
  case sport
  when "NFL"
    sport_url = 'nfl-ot1'
    api_key   = '5etueuh9u3a8auueywb7pesw'
  when "NBA"
    sport_url = 'nba-t3'
    api_key   = 'uqpj2aeucyf5erk28py2xzqu'
  end
  
  begin
    schedule = JSON.parse(`curl -s http://api.sportradar.us/#{sport_url}/games/#{2015}/REG/schedule.json?api_key=#{api_key}`)
  rescue Exception => msg
    if msg.message.include? 'Developer Over Rate'
      puts "Error: Too many queries this month"
      exit
    elsif msg.message.include? 'Developer Over Qps'
      sleep 1
      game = JSON.parse(`curl -s http://api.sportradar.us/#{sport_url}/games/#{id}/pbp.json?api_key=#{api_key}`)
    else
      puts msg.message
      game = nil
    end
  end
  
  return schedule, sport_url, api_key
end

def get_games(schedule, sport, sport_url, api_key)
  
  game_ids = []
  
  case sport
  when "NFL"  
    schedule["weeks"].each do |w|
      w["games"].each do |g|
        game_ids +=  [g["id"]]
      end
    end
  when "NBA"
    schedule["games"].each do |g|
      game_ids +=  [g["id"]]
    end  
  end  

  n = 1
  l = 5
  #l = game_ids.length

  games = []

  game_ids.each do |id|
    clear_line
    
    print "Loading game #{n}/#{l} (#{(100.0*n/l).round}%)..."
    
    exit if n == l
    n += 1
    
    begin
      game = JSON.parse(`curl -s http://api.sportradar.us/#{sport_url}/games/#{id}/pbp.json?api_key=#{api_key}`)
    rescue Exception => msg
      if msg.message.include? 'Developer Over Rate'
        puts "Error: Too many queries this month"
        exit
      elsif msg.message.include? 'Developer Over Qps'
        sleep 1
        game = JSON.parse(`curl -s http://api.sportradar.us/#{sport_url}/games/#{id}/pbp.json?api_key=#{api_key}`)
      else
        puts msg.message
        game = nil
      end
    end
    print "\b"*30
    games += [game]
  end
  
  return games.select { |g| !g.nil? }
end

if ARGV.empty?
  puts "Error: Needs a year"
  exit
end

if ["NFL", "NBA"].include? ARGV[0].upcase
  sport = ARGV[0].upcase
else
  puts "Unsupported sport"
end
if ARGV[1].to_i.to_s == ARGV[1]
  year = ARGV[1].to_i
else
  puts "Needs year"
  exit
end
  
print "Loading Schedule..."

schedule = get_schedule(sport, year)

clear_line
print "Loading games..."

games = get_games(schedule[0], sport, schedule[1], schedule[2])

clear_line
print "Saving games..."

f = File.open("./data/#{sport}#{year}.json", "w")
f.write games.to_json

clear_line
puts "Games saved."
     
