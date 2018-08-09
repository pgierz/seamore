require "json"


class DataRequest
  def initialize(paths)
    @tables = paths.map {|x| DataRequestTable.new(x)}
    @tables.each {|x| raise "tables have different data request versions (#{@tables.first.version}@#{@tables.first.path} vs #{x.version}@#{x.path})" if @tables.first.version != x.version}
    @tables = @tables.sort_by {|t| t.table_id}
    
    # merge variables with identical variable_id and frequency which may appear in multiple tables
    # sort by name+interval+frequency, so we the following order:
    #      var1 0.125 3hr   [table1]
    #      var2 0.125 3hr   [table42]
    #      var2 0.125 3hrPt [table1]
    vars = @tables.collect_concat {|t| t.variables}
    merged_vars = []
    vars = vars.sort_by {|v| "#{v.out_name} #{v.tables.first.approx_interval} #{v.frequency}"}
    vars.each do |v|
      if(merged_vars.last && merged_vars.last.out_name == v.out_name && merged_vars.last.frequency == v.frequency)
        merged_vars.last.add_table(*v.tables)
      else
        merged_vars << v
      end
    end
    
    @variables = merged_vars
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


  # print variables and frequencies, so one knows which data to generate for a simulation (table names are appended)
  # sorted by name+interval+frequency, so we the following order:
  #      var1 0.125 3hr   [table1]
  #      var2 0.125 3hr   [table42]
  #      var2 0.125 3hrPt [table1]
  def print
    @variables.each do |v|
      puts "#{v.out_name}::#{v.frequency} [#{v.tables.map{|t| t.table_id}.join(' ')}]"
    end
  end
end


class Variable < OpenStruct
  attr_reader :tables
  
  def method_missing(m, *args, &block)
    raise "no method '#{m}'"
  end
  
  
  def add_table(t)
    @tables ||= []
    @tables << t
  end
end


class DataRequestTable
  attr_reader :path
  def initialize(path)
    @path = path
    begin
      @data = JSON.parse File.read(path)
    rescue JSON::ParserError => e
      raise "file #{path}: #{e.message}"
    end
    raise "missing 'Header' entry at #{@path}" unless @data.has_key?("Header")
    raise "missing 'table_id' in 'Header' entry at #{@path}" unless @data["Header"].has_key?("table_id")
    raise "missing 'mip_era' in 'Header' entry at #{@path}" unless @data["Header"].has_key?("mip_era")
  end
  
  
  def frequencies
    (@data["variable_entry"].values.map {|v| v["frequency"]}).uniq
  end


  def variable_ids
    @data["variable_entry"].keys.sort
  end


  def variables
    vars = @data["variable_entry"].keys.sort.map do |k|
      var = @data["variable_entry"][k]
      JSON.parse(var.to_json, object_class: Variable)
    end
    vars.each {|v| v.add_table(self)}
    vars
  end


  def version
    @data["Header"]["data_specs_version"]
  end
  
  
  def approx_interval
    @data["Header"]["approx_interval"]
  end
  
  
  def table_id
    # chop of the "Table " prefix as it is not allowed according to the "controlled vocabularies"
    raise "can not determine table_id: <#{@path}>" unless /Table (?<table_id>\w+)$/ =~ @data["Header"]["table_id"]
    table_id  
  end  
end
