require 'json'

# The algorithm
def algorithm(subgame1, subgame2)
  return (subgame1.points - subgame2.points).abs
end

# Classes
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

# Misc.
def clear_line
  print "\r" + " "*100 + "\b"*100
end

# Parse game
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

# Parse season
def json_load(json_file, periods, sport)
  processed_games = []
  
  games = JSON.parse(File.read(json_file))
  games = games.select { |g| g["status"] == "closed" }
  
  games.each do |game|
    processed_games << process(game, periods, sport)
  end
  
  return processed_games
end

# Load files
def convert_to_subgames(matches)  
  subgames = matches.map { |m| m.subgames }.flatten
    
  return subgames
end
