require_relative "fesom_file.rb"

class FesomOutputDir
  PATTERN_ENV_KEY = "SEAMORE_FESOM_FILE_PATTERN"
  def self.pattern
    pattern_txt = '(?<variable_id>\w+)_fesom_(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})\.nc\Z' # default pattern to match e.g. thetao_fesom_20420101.nc, to match e.g. hist_fesom_thetao_20420101.nc set SEAMORE_FESOM_FILE_PATTERN to '_fesom_(?<variable_id>\w+)_(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})\.nc\Z'
    
    if(ENV.has_key? PATTERN_ENV_KEY)
      pattern_txt = ENV[PATTERN_ENV_KEY]
    end
    
    r = Regexp.new pattern_txt
    required_regexp_names = ["variable_id", "year", "month", "day"]
    unless (required_regexp_names-r.names).empty?
      raise "#{PATTERN_ENV_KEY} requires these named groups: #{required_regexp_names.inspect} but the pattern is: #{r.inspect}"
    end
      
    r
  end


  attr_reader :variable_files

  def initialize(d, first_year=nil, last_year=nil, verbose=true)
    filepattern = FesomOutputDir.pattern  
    eligible_files = Dir[File.join(d,"*")].grep(filepattern)
    puts "# #{PATTERN_ENV_KEY}='#{filepattern.source}' is matching #{eligible_files.size} files in directory #{d}" if verbose
    
    # remove any duplicate files (which are e.g. introduced via symlinks in the output directory)
    realpath_groups = eligible_files.group_by {|f| File.realpath(f)}
    eligible_files = []
    realpath_groups.each do |realpath, given_paths|
      eligible_files << realpath
    end  
    
    @variable_files = []
    eligible_files.each do |f|
      match = filepattern.match(File.basename(f))
      if(first_year && last_year) # might be nil, i.e. read every year
        if(first_year <= match[:year].to_i && match[:year].to_i <= last_year)
          @variable_files << FesomYearlyOutputFile.new(variable_id: match[:variable_id], year: match[:year], month: match[:month], day: match[:day], path: f)
        end
      else
        @variable_files << FesomYearlyOutputFile.new(variable_id: match[:variable_id], year: match[:year], month: match[:month], day: match[:day], path: f)
      end
    end    
    
    @variable_files.sort!
  end
  
  
  def to_s
    @variable_files.inject('') {|sum,f| sum + "#{f}\n"}
  end
  
end
