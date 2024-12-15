class DiceRoller
  # Initializes the roller with a log of rolls if needed
  def initialize
    @roll_log = []
  end

  # Rolls a die with the specified number of sides
  # For example, roll_die(20) rolls a d20
  def roll_die(sides)
    raise ArgumentError, "Number of sides must be greater than 0" if sides <= 0

    result = rand(1..sides)
    log_roll(sides, result)
    result
  end

  # Rolls multiple dice of the same type and returns the total and individual results
  # For example, roll_multiple_dice(3, 6) rolls 3d6
  def roll_multiple_dice(count, sides)
    raise ArgumentError, "Count must be greater than 0" if count <= 0

    results = Array.new(count) { roll_die(sides) }
    {
      total: results.sum,
      rolls: results
    }
  end

  # View the log of rolls (optional for debugging or record-keeping)
  def view_roll_log
    @roll_log
  end

  private

  # Logs each roll for future reference
  def log_roll(sides, result)
    @roll_log << { sides: sides, result: result, timestamp: Time.now }
  end
end
