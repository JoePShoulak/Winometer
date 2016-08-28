require './lib/nfl_helper'

subgame1 = Subgame.new
subgame1.name = "Packers"
subgame1.points = 7

subgame2 = Subgame.new
subgame2.name = "Vikings"
subgame2.points = 10

subgame3 = Subgame.new
subgame3.name = "Bears"
subgame3.points = 14

describe "A Subgame" do   
  it "should have a name" do
    expect(subgame1.name.length).to be > 0
  end
  
  it "should be able to find the distance to a game" do
    expect(subgame1.distance_to subgame2).to be > 0
  end
  
  it "should be able to find the closest game in a list (by algorithm)" do
    subgames = [subgame2, subgame3]

    expect(subgame1.distance_to(subgame2) < subgame1.distance_to(subgame3)).to be true
    expect(subgame1.find_closest subgames).to be == subgame2
  end
end

describe "A Match," do
  match  = Match.new(subgame1, subgame2)
  
  context "when the scores are different," do
    it "should return self.tie? as false" do 
      expect(match.tie?).to be false
    end
    
    it "should have a winner and a loser, and they shouldn't be the same" do
      expect(match.subgames.include? match.winner).to be true
      expect(match.subgames.include? match.loser).to be true
      expect(match.winner).not_to be match.loser
    end
  end
  
  context "when the scores are the same," do
    it "should return self.tie? as true" do 
      match.subgame1.points = match.subgame2.points
      
      expect(match.tie?).to be true
    end
    
    it "should not have a winner or loser" do
      match.subgame1.points = match.subgame2.points

      expect(match.winner).to be nil
      expect(match.loser).to  be nil
    end
  end
end