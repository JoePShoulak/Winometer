require 'json'

# The algorithm
def algorithm(subgame1, subgame2)
  return (subgame1.points - subgame2.points).abs
end

# Misc.
def clear_line
  print "\r" + " "*100 + "\b"*100
end

# Classes
class CLI
  def initialize
    @args = Hash.new
    
    if ARGV.empty?
      puts "Error: No arguments"
      exit
    end
  end
  
  attr_accessor :args
  
  def add_arg(key, value)
    @args[key] = value
  end
  
  def change_arg(key, new_value)
    self.args[key] = new_value
  end
end

class Subgame
  def initialize
    @points = 0
    @final_score = 0
  end
  
  attr_accessor :name, :points, :final_score, :id, :win_percentage
  
  def score
    return [self.name, self.points]
  end
  
  def distance_to(game)
    return algorithm(self, game)
  end
  
  def find_closest(list_of_games)
    return list_of_games.sort_by { |g| self.distance_to g }[0]
  end
  
  def same_as?(game)
    return self.id == game.id
  end
end

class Match
  def initialize(subgame1, subgame2)
    @subgame1 = subgame1
    @subgame2 = subgame2
    
    self.subgame1.win_percentage = 100*(0.5 + self.spread/40.0)
    self.subgame2.win_percentage = 100 - self.subgame1.win_percentage
  end
  
  attr_accessor :subgame1, :subgame2, :true_winner, :true_tie
  
  def subgames
    return [@subgame1, @subgame2]
  end
  
  def tie?
    self.subgame1.points == self.subgame2.points
  end
  
  def winner
    return self.tie? ? nil : self.subgames.max_by { |g| g.points }
  end
  
  def loser
    return self.tie? ? nil : self.subgames.min_by { |g| g.points }
  end
  
  def info
    return self.subgame1.info + self.subgame2.info
  end
  
  def spread
    return self.subgame1.points - self.subgame2.points
  end
end

class Simulation
  def initialize(sport, year, periods, verbose)
    @sport = sport
    @year = year
    @periods = periods
    @verbose = verbose
    
    @total = 0
    @correct = 0
    @unknown = 0
    
    @json_url = "./data/#{self.sport}#{self.year}.json"

    puts "Loading File..."
    @matches = self.json_load
    clear_line
  end
  
  attr_accessor :matches, :total, :correct, :unknown, :sport, :year, :periods, :verbose, :json_url
  
  def process(game, periods, sport)
    subgame_home = Subgame.new
    subgame_away = Subgame.new 

    subgame_home.id = game["id"]
    subgame_away.id = game["id"]
  
    case sport.upcase
    when "NFL"
      home = game["summary"]["home"]
      away = game["summary"]["away"]
    when "NBA"
      home = game["home"]
      away = game["away"]
    end

    home_market = home["market"]
    away_market = away["market"]
    
    home_name = home["name"]
    away_name = away["name"]
  
    subgame_home.name = home_market + " " + home_name
    subgame_away.name = away_market + " " + away_name
  
    subgame_home.points = 0
    subgame_away.points = 0
    
    game["periods"].length.times do |pe| # For each period
      period = game["periods"][pe]
    
      home_points = period["scoring"]["home"]["points"].to_i
      away_points = period["scoring"]["away"]["points"].to_i
    
      subgame_home.points += home_points unless pe >= periods
      subgame_away.points += away_points unless pe >= periods
    
      subgame_home.final_score += home_points
      subgame_away.final_score += away_points
    end
  
    m = Match.new(subgame_home, subgame_away)
  
    m.true_winner = [subgame_home, subgame_away].sort_by { |s| s.final_score }[1]
    m.true_tie = ( subgame_home.final_score == subgame_away.final_score )
      
    return m
  end
    
  def json_load
    processed_games = []
  
    games = JSON.parse(File.read(self.json_url))
    games = games.select { |g| g["status"] == "closed" }
  
    games.each do |game|
      processed_games << process(game, self.periods, self.sport)
    end
  
    return processed_games
  end  
      
  def load_matches!
    puts "Loading File..."
    clear_line
  end
  
  def simulate
    print "Loading File..."

    self.matches.select { |m| !m.true_tie }.each do |match|
      self.total += 1

      if !match.tie? && !match.true_tie
        self.correct += 1 if match.winner.name == match.true_winner.name
  
        if self.verbose
          match.subgames.each do |subgame|
            puts "#{subgame.name}"
            puts "\tCheck Score: #{subgame.points}"
            puts "\tFinal Score: #{subgame.final_score}"
          end
    
          puts "Prediction: "
          puts "\t#{match.winner.name} are ahead by #{match.spread.abs}"
    
          match.subgames.each do |subgame|
            puts "\t#{subgame.name}: #{subgame.win_percentage}%"
          end
    
          puts "\tResult: #{match.winner.name == match.true_winner.name}"
          puts 
        end
      else
        self.unknown += 1
      end
    end

    clear_line  

    correct_ratio = correct.to_f/total
    unknown_ratio = unknown.to_f/total
    theoretical_ratio = correct.to_f/(total - unknown)

    correct_percent = 100*correct_ratio.round(2)
    unknown_percent = 100*unknown_ratio.round(2)
    theoretical_percent = 100*theoretical_ratio.round(2)

    message = "Results: #{periods} period(s), #{correct_percent}% accurate, #{unknown_percent}% unknown, #{theoretical_percent}% theoretical."
    numbers = [correct_percent, unknown_percent, theoretical_percent]

    return [message] + numbers
  end
  
  def run
    self.load_matches!
    
    if self.periods == "all"
      self.correct = 0
      self.unknown = 0
      self.theoretical = 0
      (1..3).each do |n|
        r = self.simulate(sport, year, n, verbose)
        puts r[0]
        self.correct += r[1]
        self.unknown += r[2]
        self.theoretical += r[3]
      end
      puts "Average Correct: #{(correct/3).round(2)}%"
      puts "Average Unknown: #{(unknown/3).round(2)}%"
      puts "Average Theoretical: #{(theoretical/3).round(2)}%"
    else
      puts self.simulate[0]
    end
  end
end

class Radar
  def initialize(sport, year)
    @sport = sport
    @year = year
    @games = Array.new
    @ids = Array.new
    
    case @sport
    when "NBA"
      @url = 'nba-t3'
      @key = 'uqpj2aeucyf5erk28py2xzqu'
    when "NFL"
      @url = 'nfl-ot1'
      @key = '5etueuh9u3a8auueywb7pesw'
    end
  end
  
  attr_accessor :schedule, :games, :ids, :url, :key, :sport, :year
  
  def get_schedule
    print "Loading Schedule..."
    
    begin
      self.schedule = JSON.parse(`curl -s http://api.sportradar.us/#{self.url}/games/#{self.year}/REG/schedule.json?api_key=#{self.key}`)
    rescue Exception => msg
      if msg.message.include? 'Developer Over Rate'
        puts "Error: Too many queries this month"
        exit
      elsif msg.message.include? 'Developer Over Qps'
        sleep 1
        self.schedule = JSON.parse(`curl -s http://api.sportradar.us/#{self.url}/games/#{self.year}/REG/schedule.json?api_key=#{self.key}`)
      else
        puts msg.message
        exit
      end
    end
    
    clear_line
  end
  
  def get_ids
    case sport
    when "NFL"  
      schedule["weeks"].each do |w|
        w["games"].each do |g|
          self.ids +=  [g["id"]]
        end
      end
    when "NBA"
      schedule["games"].each do |g|
        self.ids +=  [g["id"]]
      end  
    end  
  end
  
  def get_games
    print "Loading games..."

    n = 1
    l = 5
    #l = game_ids.length
    
    self.ids.each do |id|
      clear_line
    
      print "Loading game #{n}/#{l} (#{(100.0*n/l).round}%)..."
    
      exit if n == l
      n += 1
    
      begin
        game = JSON.parse(`curl -s http://api.sportradar.us/#{self.url}/games/#{id}/pbp.json?api_key=#{self.key}`)
      rescue Exception => msg
        if msg.message.include? 'Developer Over Rate'
          puts "Error: Too many queries this month"
          exit
        elsif msg.message.include? 'Developer Over Qps'
          sleep 1
          game = JSON.parse(`curl -s http://api.sportradar.us/#{self.url}/games/#{id}/pbp.json?api_key=#{self.key}`)
        else
          puts msg.message
          game = nil
        end
      end
      print "\b"*30
      self.games += [game]
    end
  
    self.games = games.select { |g| !g.nil? }
    
    clear_line
  end
  
  def save_games
    print "Saving games..."
    
    f = File.open("./data/#{self.sport}#{self.year}.json", "w")
    f.write(self.games.to_json)
    
    clear_line
    puts "Games saved."
  end
end