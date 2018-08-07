require "json"


class DataRequestTable
  def initialize(path)
    @data = JSON.parse File.read(path)
  end


  def variable_ids
    @data["variable_entry"].keys
  end


  def version
    @data["Header"]["data_specs_version"]
  end
end
