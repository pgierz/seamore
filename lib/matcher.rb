require_relative "../lib/fesom_output_dir.rb"
require_relative "../lib/data_request.rb"
require_relative "../lib/fesom_possible_var.rb"
require_relative "../lib/step.rb"


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
    fesom_variables.uniq! {|fevar| [fevar.variable_id, fevar.time_method, fevar.unit]}
    fesom_variables.each do |fevar|
      # match the variable_id and time_method
      cmipvar = request.variables.find {|v| v.variable_id == fevar.variable_id && v.time_method == fevar.time_method}

      if(cmipvar)
        table_txts = cmipvar.table_ids.map {|t| "#{cmipvar.variable_id}_#{t}"}
        
        # match also unit
        if(cmipvar.unit == fevar.unit)
          puts "cmorize #{fevar.variable_id}_#{fevar.frequency} => [#{table_txts.join(', ')}]"
        else
          # see if we could auto convert the unit
          if CMORizer::Step::AUTO_CONVERT_UNIT.auto_convert_unit_possible?(fevar.unit, cmipvar.unit)
            puts "cmorize #{fevar.variable_id}_#{fevar.frequency} => [#{table_txts.join(', ')}] # automatically converting unit from '#{fevar.unit}' to '#{cmipvar.unit}'"
          else
            puts "# NO match: #{fevar.variable_id} '#{fevar.unit}' #{fevar.frequency} #{fevar.time_method} (!! #{cmipvar.variable_id} '#{cmipvar.unit}' exists in table(s) #{cmipvar.table_ids.join(', ')})"
          end
        end
      else
        puts "# NO match: #{  fevar.variable_id} '#{fevar.unit}' #{fevar.frequency} #{fevar.time_method}"
      end
    end
  end
end
