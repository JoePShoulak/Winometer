require './lib/simulate_helper'

def simulate(sport, year, periods, verbose)
  total   = 0
  correct = 0
  unknown = 0

  print "Loading Testing File..."

  matches = json_load("./data/#{sport}2015.json", periods, sport)

  clear_line

  matches.select { |m| !m.true_tie }.each do |match|
    total += 1
  
    if !match.tie? && !match.true_tie
      correct += 1 if match.winner.name == match.true_winner.name
    
      if verbose
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
      unknown += 1
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

def gui
  
end

if ARGV.empty?
  puts "Needs arguments"
  exit
end

if ARGV[0] == "gui"
  gui
elsif "NFL, NBA".include? ARGV[0].upcase
  sport = ARGV[0].upcase
  if ARGV[1].to_i.to_s == ARGV[1]
    year = ARGV[1].to_i
  else
    puts "Needs year"
    exit
  end
  if ARGV[2].to_i.to_s == ARGV[2]
    periods = ARGV[2].to_i
  elsif ARGV[2] == "all"
    periods = "all"
  else
    puts "Needs periods"
    exit
  end
  if ARGV[3] == "verbose"
    verbose = true
  else
    verbose = false
  end
     
  if periods == "all"
    correct = 0
    unknown = 0
    theoretical = 0
    (1..3).each do |n|
      r = simulate(sport, year, n, verbose)
      puts r[0]
      correct += r[1]
      unknown += r[2]
      theoretical += r[3]
    end
    puts "Average Correct: #{(correct/3).round(2)}%"
    puts "Average Unknown: #{(unknown/3).round(2)}%"
    puts "Average Theoretical: #{(theoretical/3).round(2)}%"
  else
    puts simulate(sport, year, periods, verbose)[0]
  end
else 
  puts "Sport unsupported"
end
      
  


