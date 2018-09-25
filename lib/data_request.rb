require "json"
require_relative "frequency.rb"


class DataRequest
  attr_reader :variables
  

  def self.approx_interval_for_table(table)
    approx_interval = {"3hr" => 3.0/24,
    "6hrLev" => 6.0/24,
    "6hrPlev" => 6.0/24,
    "6hrPlevPt" => 6.0/24,
    "AERday" => 1.0,
    "AERhr" => 1.0/24, # note, data request 01.00.27 says "1.0" here, but this seems to be wrong
    "AERmon" => 30.0,
    "AERmonZ" => 30.0,
    "Amon" => 30.0,
    "CF3hr" => 3.0/24,
    "CFday" => 1.0,
    "CFmon" => 30.0,
    "day" => 1.0,
    "E3hr" => 3.0/24,
    "E3hrPt" => 3.0/24,
    "E6hrZ" => 6.0/24,
    "Eday" => 1.0,
    "EdayZ" => 1.0,
    "Emon" => 30.0,
    "EmonZ" => 30.0,
    "Eyr" => 365.0,
    "ImonAnt" => 30.0,
    "ImonGre" => 30.0,
    "IyrAnt" => 365.0,
    "IyrGre" => 365.0,
    "LImon" => 30.0,
    "Lmon" => 30.0,
    "Oclim" => 30.0,
    "Oday" => 1.0,
    "Odec" => 3650.0,
    "Omon" => 30.0,
    "Oyr" => 365.0,
    "SIday" => 1.0,
    "SImon" => 30.0}[table]

    raise "can not find approx_interval for table #{table}" unless approx_interval
    approx_interval
  end


  # create from all tables in given dir, omitting non-table files from the default tables directory at https://github.com/PCMDI/cmip6-cmor-tables
  def self.new_from_tables_dir(path)
    eliglible_files = Dir["#{path}/CMIP6_*.json"]-["#{path}/CMIP6_CV_test.json", "#{path}/CMIP6_coordinate.json", "#{path}/CMIP6_CV.json", "#{path}/CMIP6_formula_terms.json", "#{path}/CMIP6_grids.json"]
    raise "no eliglible json tables found at path <#{path}>" if eliglible_files.empty?
    DataRequest.new eliglible_files
  end


  def initialize(paths)
    @tables = paths.map {|x| DataRequestTable.new(x)}
    @tables.each {|x| raise "tables have different data request versions (#{@tables.first.version}@#{@tables.first.path} vs #{x.version}@#{x.path})" if @tables.first.version != x.version}
    @tables = @tables.sort_by {|t| t.table_id}
    
    # merge variables with identical variable_id and frequency which may appear in multiple tables
    # sort by name+interval+frequency, so we the following order:
    #      var1 0.125 3hr   [table1]
    #      var2 0.125 3hr   [table42]
    #      var2 0.125 3hrPt [table1]
    vars = @tables.collect_concat {|t| t.variable_entries}
    merged_vars = []
    # sort vars by merge criterium (variable_id, unit, time_method) and additionally by interval and table_id
    vars = vars.sort_by {|v| "#{v.variable_id} #{v.unit} #{v.time_method} #{v.table.approx_interval} #{v.table.table_id}"}
    vars.each do |v|
      # merge vars with equal variable_id, unit, time_method
      if(merged_vars.last && merged_vars.last.variable_id == v.variable_id && merged_vars.last.unit == v.unit && merged_vars.last.time_method == v.time_method)
        merged_vars.last.merge_table_var_entry(v)
      else
        merged_vars << DataRequestVariable.new_from_table_var_entry(v)
      end
    end
    
    @variables = merged_vars
  end


  def find(variable_id)
    @variables.find {|v| variable_id == v.variable_id}
  end


  def variable_ids
    @variables.map {|v| v.variable_id}
  end


  def version
    @tables.first.version
  end
  
  
  def table_ids
    @tables.collect_concat {|t| t.table_id}
  end
  
  
  # all variables and frequencies as string, so one knows which data to generate for a simulation (table names are appended)
  # sorted by name+interval+frequency, so we the following order:
  #      var1 0.125 3hr   [table1]
  #      var2 0.125 3hr   [table42]
  #      var2 0.125 3hrPt [table1]
  def to_s
    s = "=== #{version} ===\n"
    @variables.each do |v|
      s += "#{v}\n"
    end
    s
  end

end


class DataRequestVariable
  attr_reader :variable_id, :unit, :description, :time_method, :frequencies, :realms

  def self.new_from_table_var_entry(var_entry)
    DataRequestVariable.new(var_entry.variable_id, var_entry.unit, var_entry.description, var_entry.time_method, var_entry.table, var_entry.frequency_name, var_entry.realms)
  end


  def initialize(variable_id, unit, description, time_method, table, frequency, realms)
    @variable_id = variable_id
    @unit = unit
    @description = description
    @time_method = time_method
    @tables = [table]
    @frequencies = [frequency]
    @realms = realms
  end
  
  
  def merge_table_var_entry(var_entry)
    @tables << var_entry.table
    @frequencies << var_entry.frequency_name
    # we do not merge time methods, as we treat identical variable_ids with different time methods as different variables
  end
  
  
  def table_ids
    @tables.map {|t| t.table_id}
  end
  
  
  def frequency_in_table(table_id)
    i = table_ids.index(table_id)
    raise "variable_id '#{variable_id}' is not associated with table_id '#{table_id}', available table_id(s): #{table_ids.join(', ')}" unless i
    @frequencies[i]
  end
  
  
  def to_s
    "#{variable_id} '#{unit}' [#{frequencies.join(' ')}] [#{@tables.map{|t| t.table_id}.join(' ')}]"
  end
end


class TableVarEntry
  attr_reader :table, :frequency_name, :time_method


  def initialize(variable_entry_key:, entry_data:, table:)
    @variable_entry_key = variable_entry_key    
    @data = entry_data
    @table = table
    @frequency_name = @data['frequency']
    @time_method = Frequency.for_name(@data['frequency']).time_method
  end
  

  def variable_id
    @variable_entry_key # it is not clear whether the variable_id is stored as 'out_name' or the 'variable_entry' key as these differ for e.g. difmxybo in data request 0.1.00.27
  end
    
  
  def unit
     @data['units']
  end


  def description
     @data['comment']
  end
  
  
  def realms
    @data['modeling_realm'].split(' ')
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


  def variable_entries
    @data["variable_entry"].keys.sort.map do |k|
      TableVarEntry.new(variable_entry_key: k, entry_data: @data["variable_entry"][k], table: self)
    end
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
