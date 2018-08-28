require_relative "../lib/fesom_output_dir.rb"
require_relative "../lib/data_request.rb"
require_relative "../lib/fesom_possible_var.rb"


class Matcher
  def self.print_matching_possible(request_dir:)
    possible_vars = FesomPossibleVar.create_from_fortran_code(FESOM_VARIABLE_INITIALIZATION_CODE, sort: true)
    request = DataRequest.new_from_tables_dir File.expand_path(request_dir)

    self.print_matching(request, possible_vars) 
  end
  
  
  def self.print_matching_available(request_dir:, output_dir:)
    output_vars = FesomOutputDir.new(File.expand_path output_dir).variable_files
    request = DataRequest.new_from_tables_dir File.expand_path(request_dir)
    
    self.print_matching(request, output_vars) 
  end


  def self.print_matching(request, fesom_variables)    
    fesom_variables.each do |fevar|
      cmipvar = request.variables.find {|v| v.variable_id == fevar.variable_id && v.time_method == fevar.time_method && v.unit == fevar.unit}
      if(cmipvar)
        table_txts = cmipvar.table_ids.map {|t| "#{cmipvar.variable_id}_#{t}"}
        puts "cmorize #{fevar.variable_id}_#{fevar.frequency} => [#{table_txts.join(', ')}]"
      else
        cmipvar = request.variables.find {|v| v.variable_id == fevar.variable_id}
        if(cmipvar)
          puts "# NO match: #{fevar} (!! #{cmipvar.variable_id} '#{cmipvar.unit}' exists in datarequest)"
        else
          puts "# NO match: #{fevar}"
        end
      end
    end
  end
end
