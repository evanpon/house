class Scorecard < ActiveRecord::Base
  belongs_to :home
  UNKNOWN = 0
  POOR = 1
  AVERAGE = 2
  GOOD = 3
  AWESOME = 4

  def calculate_score
    score = 0
    score += points(:location) * 2
    [:kitchen, :layout, :light, :charm, :potential, :yard].each do |sym|
      score += points(sym)
    end
    score
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
