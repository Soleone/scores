FILENAME = "/Users/Soleone/Stuff/Backup/Dominion_Scores.txt"
PLAYERS  = ["Liz", "Dennis"]
COMMANDS = ['add', 'show', 'remove', 'server']

class Session
  FILENAME = 
  attr_reader :players, :game_scores
  
  def initialize(players, filename)
    @filename = filename
    @players = players
    @game_scores = []
    load!
  end
  
  def load!
    score_lines = File.readlines(@filename).select{|line| line =~ /-?\d+ +- +-?\d+/ }
    @game_scores = score_lines.map{|line| GameScore.new(line, self) }
  end
  
  def add(score)
    File.open(@filename, 'a') do |file|
      file.write("\n")
      file.write(score)
    end
  end

  def remove
    lines = File.readlines(@filename)
    lines.pop
    File.open(@filename, 'w'){|file| file.write(lines) }
  end

  def draws
    @draws ||= @game_scores.select{|game| game.draw? }.size
  end

  def wins(player = nil)
    @wins ||= @game_scores.inject({players.first => 0, players.last => 0}) do |memo, game_score|
      memo[game_score.winner] += 1 if game_score.winner
      memo
    end
    player ? @wins[player] : @wins
  end
  
  def winner
    max = players.inject do |memo, player|
      wins(memo) > wins(player) ? memo : player
    end
    players.collect{|p| wins(p) }.all?{|wins| wins(max) > wins } ? max : nil
  end
  
  def totals(player)
    all_scores(player).inject{|sum, score| sum + score }
  end
  
  def all_scores(player = nil)
    @all_scores ||= @game_scores.collect{|game| [game.scores.first, game.scores.last] }
    player ? @all_scores.collect{|scores| scores[players.index(player)]} : @all_scores
  end
  
  def highscore(player = nil)
    max = all_scores(player).max if player
    player ? max : players.collect{|p| highscore(p)}.max
  end

  def lowscore(player = nil)
    min = all_scores(player).min if player
    player ? min : players.collect{|p| lowscore(p)}.min
  end
  
  def highscore?(player)
    highscore == highscore(player)
  end
  
  def lowscore?(player)
    lowscore == lowscore(player)
  end
end


class GameScore
  attr_reader :session, :scores
    
  def initialize(scores, session)
    @scores = scores.scan(/-?\d+/).map{|s| s.to_i }
    @session = session
  end
  
  def draw?
    scores.first == scores.last
  end

  def winner
    return nil if draw?
    scores.first > scores.last ? session.players.first : session.players.last
  end
  
  def score(player)
    scores[session.players.index(player)]
  end
end


class GameScoreCLI
  def initialize(argv)
    @argv = argv
    @session = Session.new(PLAYERS, FILENAME)
  end
  
  def start
    command = @argv[0]
    unless COMMANDS.include?(command)
      puts "Unknown command, use one of #{COMMANDS.map{|c| "\"#{c}\""}.join(', ')} -> e.g. \"score show\""
    end
    case command
    when 'add'
      score = @argv[1]
      @session.add(score)
      @session.load!
      show
    when 'show'
      show
    when 'remove'
      @session.remove
      @session.load! 
      show
    when 'server'
      require File.dirname(__FILE__) + '/game_score_server'
      GameScoreServer.run! :host => "localhost", :port => 1234
    end    
  end
  
  def show
    results = { :wins => @session.wins, :draws => @session.draws, :all_scores => @session.all_scores }
    puts "#{PLAYERS[0]} - #{PLAYERS[1]}"
    puts "%#{PLAYERS[0].size}d - %d  #{' ' * PLAYERS[1].size}Wins (with #{results[:draws]} Draws)" % [ results[:wins][PLAYERS[0]], results[:wins][PLAYERS[1]] ]
    puts "-" * (PLAYERS[0].size + PLAYERS[1].size + 3)
    results[:all_scores].each do |score|
      puts "%#{PLAYERS[0].size}d - %d" % [ score[0], score[1] ]
    end
    puts "-" * (PLAYERS[0].size + PLAYERS[1].size + 3)
    puts "%#{PLAYERS[0].size}d - %d Total" % [ @session.totals(PLAYERS[0]), @session.totals(PLAYERS[1]) ]  
  end
end


# MAIN
if $0 == __FILE__
  GameScoreCLI.new(ARGV).start
end