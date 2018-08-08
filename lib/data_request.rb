require "json"


class DataRequest
  def initialize(paths)
    @tables = paths.map {|x| DataRequestTable.new(x)}
    @tables.each {|x| raise "tables have different data request versions (#{@tables.first.version}@#{@tables.first.path} vs #{x.version}@#{x.path})" if @tables.first.version != x.version}
    @tables = @tables.sort_by {|t| t.table_id}
  end


  def variable_ids
    (@tables.collect_concat {|t| t.variable_ids}).sort
  end


  def version
    @tables.first.version
  end
  
  
  def table_ids
    @tables.collect_concat {|t| t.table_id}
  end
end


class DataRequestTable
  attr_reader :path
  def initialize(path)
    @path = path
    @data = JSON.parse File.read(path)
  end


  def variable_ids
    @data["variable_entry"].keys.sort
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
