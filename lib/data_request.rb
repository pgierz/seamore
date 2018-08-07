require "json"


class DataRequest
  def initialize(path)
    @data = JSON.parse File.read(path)
  end


  def variable_ids
    @data["variable_entry"].keys
  end

end
