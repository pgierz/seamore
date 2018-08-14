require "json"


class DataRequest
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


  def self.approx_interval_for_frequency(frequency)
    approx_interval = {
    "3hr" => 3.0/24,
    "3hrPt" => 3.0/24,
    "6hr" => 6.0/24,
    "6hrPt" => 6.0/24,
    "day" => 1.0,
    "dec" => 3650.0,
    "mon" => 30.0,
    "monC" => 30.0,
    "monPt" => 30.0,
    "yr" => 365.0,
    "yrPt" => 365.0}[frequency]

    raise "can not find approx_interval for frequency #{frequency}" unless approx_interval
    approx_interval
  end


  # create from all tables in given dir, omitting non-table files from the default Tables directory at https://github.com/PCMDI/cmip6-cmor-tables
  def self.new_from_tables_dir(path)
    eliglible_files = Dir["#{path}/CMIP6_*.json"]-["#{path}/CMIP6_CV_test.json", "#{path}/CMIP6_coordinate.json", "#{path}/CMIP6_CV.json", "#{path}/CMIP6_formula_terms.json", "#{path}/CMIP6_grids.json"]
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
    vars = @tables.collect_concat {|t| t.variables}
    merged_vars = []
    vars = vars.sort_by {|v| "#{v.variable_id} #{v.tables.first.approx_interval} #{v.frequency}"}
    vars.each do |v|
      if(merged_vars.last && merged_vars.last.variable_id == v.variable_id && merged_vars.last.frequency == v.frequency)
        merged_vars.last.add_table(*v.tables)
      else
        merged_vars << v
      end
    end
    
    @variables = merged_vars
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
      s += "#{v.variable_id}::#{v.frequency} [#{v.tables.map{|t| t.table_id}.join(' ')}]\n"
    end
    s
  end

end


class Variable < OpenStruct
  attr_reader :tables

  def method_missing(m, *args, &block)
    raise "no method '#{m}'"
  end
  
  
  def set_variable_entry_key(k)
    @variable_entry_key = k
  end
  
  
  def variable_id
    @variable_entry_key # it is not clear whether the variable_id is stored as 'out_name' or the 'variable_entry' key as these differ for e.g. difmxybo in data request 0.1.00.27
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
    @data["variable_entry"].keys.sort.map do |k|
      var = @data["variable_entry"][k]
      v = JSON.parse(var.to_json, object_class: Variable)
      v.set_variable_entry_key k
      v.add_table self
      v
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
