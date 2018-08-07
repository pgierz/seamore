require "json"


class DataRequestTable
  def initialize(path)
    @path = path
    @data = JSON.parse File.read(path)
  end


  def variable_ids
    @data["variable_entry"].keys
  end


  def version
    @data["Header"]["data_specs_version"]
  end
  
  
  def table_id
    # chop of the "Table " prefix as it is not allowed according to the "controlled vocabularies"
    raise "can not determine table_id: <#{@path}>" unless /Table (?<table_id>\w+)$/ =~ @data["Header"]["table_id"]
    table_id  
  end
  
  
end
