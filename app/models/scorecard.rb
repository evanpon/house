class Scorecard < ActiveRecord::Base
  belongs_to :home
  UNKNOWN = 0
  POOR = 1
  AVERAGE = 2
  GOOD = 3
  AWESOME = 4

  def calculate_score
    score = 0
    score += points(:location) * 3
    [:kitchen, :layout, :light, :charm, :potential, :yard].each do |sym|
      score += points(sym)
    end
    # Normalize it on a scale of 0-100
    score == 0 ? 0 : ((score + 9) * 3.7).to_i
  end
  
  def unknown?(score)
    score == UNKNOWN || score.nil?
  end

  private
  def points(attr)
    case self.send(attr)
    when POOR
      -1
    when AVERAGE
      0
    when GOOD
      1
    when AWESOME
      2
    else
      0
    end
  end
end
