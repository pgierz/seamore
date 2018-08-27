require_relative "../lib/fesom_output_dir.rb"
require_relative "../lib/data_request.rb"


class Matcher
  def self.print_matching_available(request_dir:, output_dir:)
    output_vars = FesomOutputDir.new(File.expand_path output_dir).variable_files
    request = DataRequest.new_from_tables_dir File.expand_path(request_dir)
    
    output_vars.each do |outvar|
      cmipvar = request.variables.find {|v| v.variable_id == outvar.variable_id && v.time_method == outvar.time_method && v.unit == outvar.unit}
      if(cmipvar)
        puts "#{outvar.variable_id} #{outvar.unit} #{cmipvar}"
      else
        cmipvar = request.variables.find {|v| v.variable_id == outvar.variable_id}
        if(cmipvar)
          puts "NO match: #{outvar} (!! #{cmipvar.variable_id} '#{cmipvar.unit}' exists in datarequest)"
        else
          puts "NO match: #{outvar}"
        end
      end
    end
  end
end
