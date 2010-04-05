require 'rubygems'
require 'test/spec'
require 'score'

context "GameScore" do
end

context "Session" do
  setup do
    @session = Session.new(PLAYERS)
    @session.load_from_file(FILENAME)
  end
  
  it "should hold all players" do
    @session.players.should.be PLAYERS
  end
  
  context "all_scores" do
    it "should return all scores for each game in a 2d array" do
      scores = @session.all_scores
      scores.size.should == @session.game_scores.size
      scores.each do |score|
        score.size.should == PLAYERS.size
      end
    end
    
    it "should return all scores for a player when passes as an argument" do
      scores = @session.all_scores(PLAYERS.last)
      scores.size.should == @session.game_scores.size
    end
  end

  context "totals" do
    it "should add all the scores for a player and return it" do
      scores = @session.all_scores(PLAYERS.last)
      sum = scores.inject{ |sum, score| sum + score}
      @session.totals(PLAYERS.last).should == sum
    end
  end
  
  context "highscore" do
    it "" do
      max = File.read(FILENAME).scan(/\d+/).collect{|score| score.to_i}.max
      @session.highscore.should == max
    end    
  end
end