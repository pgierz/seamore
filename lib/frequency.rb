class TimeMethods
  ALL = [MEAN=:MEAN, POINT=:INSTANTANEOUS]
end


# https://github.com/WCRP-CMIP/CMIP6_CVs/blob/master/CMIP6_frequency.json
class Frequency
  attr_reader :name, :approx_interval, :time_method
  

  def self.for_name(n)
    tm = n.end_with?("Pt")==true ? TimeMethods::POINT : TimeMethods::MEAN
    ALL.find {|f| f.name == n.delete_suffix("Pt") && f.time_method == tm}
  end


  def initialize(name, approx_interval, time_method=TimeMethods::MEAN)
    @name = name
    @approx_interval = approx_interval
    @time_method = time_method
  end


  ALL = [
    F_hr = Frequency.new("1hr", 1.0/24),
    F_3hr = Frequency.new("3hr", 3.0/24),
    F_6hr = Frequency.new("6hr", 6.0/24),
    F_day = Frequency.new("day", 1.0), # there is no dayPt frequency
    F_mon = Frequency.new("mon", 30.0),
    F_yr = Frequency.new("yr", 365.0),
    F_dec = Frequency.new("dec", 3650.0),
    F_hrPt = Frequency.new("1hr", 1.0/24, TimeMethods::POINT),
    F_3hrPt = Frequency.new("3hr", 3.0/24, TimeMethods::POINT),
    F_6hrPt = Frequency.new("6hr", 6.0/24, TimeMethods::POINT),
    F_monPt = Frequency.new("mon", 30.0, TimeMethods::POINT),
    F_yrPt = Frequency.new("yr", 365.0, TimeMethods::POINT),
    ]
    
  
  def <=>(other)
    @approx_interval <=> other.approx_interval
  end
end
