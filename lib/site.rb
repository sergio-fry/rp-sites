require 'securerandom'
require 'spliner'

class Site < S3Record
  def self.table_name; "sites"; end;

  def alexa_rank_from_cy
    return if self[:cy].nil?

    points = {
      0.0 => 5000000.0,
      10.0 => 1114440.0,
      100.0 => 145480.0,
      200.0 => 312805.0,
      500.0 => 127358.0,
      650.0 => 41644.0,
      1000.0 => 18367.0,
      1200.0 => 9893.0,
      6600.0 => 6012.0,
      14000.0 => 1935.0,
    }

    x1 = points.keys.find_all { |k| k <= self[:cy] }.max
    x2 = points.keys.find_all { |k| k >= self[:cy] }.min

    spliner = Spliner::Spliner.new([x1, x2], [points[x1], points[x2]])

    rank = spliner[self[:cy]].round
  end
end
