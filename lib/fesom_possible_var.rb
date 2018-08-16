class TimeMethods
  ALL = [MEAN=:MEAN, POINT=:INSTANTANEOUS]
end


class FesomPossibleVar
  attr_reader :variable_id, :unit, :description, :time_method

  def initialize(variable_id, unit, description, time_method)
    @variable_id = variable_id
    @unit = unit
    @description = description
    @time_method = time_method
  end


  def self.create_from_fortran_code(code)
    code.split("\n").map do |init_line|
      /.+?, ['"](?<variable_id>[^,]+?)['"], ['"](?<description>.+?)['"], ['"](?<unit>[^,]+?)['"]\) *.*/ =~ init_line
      raise "could not parse all values: variable_id:#{variable_id.inspect}, unit:#{unit.inspect}, description:#{description.inspect}, code:'#{init_line}'" unless [variable_id, unit, description].all?
      if(variable_id == "tso")
        FesomPossibleVar.new variable_id, unit, description, TimeMethods::POINT
      else
        FesomPossibleVar.new variable_id, unit, description, TimeMethods::MEAN
      end
    end
  end
  
  
  def to_s
    "#{@variable_id}: '#{@unit}' #{@time_method} '#{@description}'"
  end
end
