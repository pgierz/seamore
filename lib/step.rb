require 'fileutils'

module CMORizer
  module Step
    class BaseStep
      def initialize(next_step)
        @next_step = next_step
        @available_inputs = {}
      end
      
      
      def set_info(experiment:, variable_id:, frequency:, table_id:, realms:)
        @experiment = experiment
        @variable_id = variable_id
        @frequency = frequency
        @table_id = table_id
        @realms = realms
      end


      def add_input(input, years, number_of_eventual_input_years)
        @available_inputs[years] = input
        
        # some steps might be able to process each file as soon as it arrives
        # others, like merge, might require the maximum number of files to be available
        if can_process?(number_of_eventual_input_years)
          sorted_years_arrays = @available_inputs.keys.sort
          sorted_inputs = @available_inputs.values_at(*sorted_years_arrays)

          sorted_years = sorted_years_arrays.flatten
          opath = create_outpath(*sorted_inputs)
          results, result_years = process(sorted_inputs, sorted_years, opath)
          
          if results && @next_step
            results.each_index do |i|
              @next_step.add_input(results[i], [result_years[i]], number_of_eventual_input_years)
            end
          end
          @available_inputs.clear
        end
      end
            
      
      private def process(inputs, years, opath) # pipe input files through all our FileCommand objects
        puts "\t#{self.class} #{inputs.join(', ')} #{opath}"
        *commands = file_commands
        command_inputs = inputs
        command_opath = nil
        commands.each_with_index do |cmd, i|
          command_opath = "#{opath}.#{i}"
          cmd.run(command_inputs, command_opath)
          command_inputs = [command_opath]
        end
        
        raise "file exists: #{opath}" if File.exist? opath
        FileUtils.mv command_opath, opath

        return [opath], years
      end
            
      
      def file_commands
        raise "overwrite with concrete implementation which returns one or many FileCommand objects"
      end
      
      
      def create_outpath(*inpaths)
        outdir = File.dirname(inpaths.first)
        step_suffix = self.class.to_s.split('::').last
        outname = 
          if inpaths.size == 1
            "#{File.basename(inpaths.last)}.#{step_suffix}"
          else
            "#{File.basename(inpaths.first, ".*")}--#{File.basename(inpaths.last)}.#{step_suffix}"
          end
        
        File.join outdir, outname
      end
    end
    
    
    class IndividualBaseStep < BaseStep
      def can_process?(number_of_eventual_input_years)
        true
      end
    end


    class JoinedBaseStep < BaseStep
      def can_process?(number_of_eventual_input_years)
        @available_inputs.keys.size == number_of_eventual_input_years
      end
    end
  end
end


require_relative "file_command.rb"
require_relative "global_attributes.rb"
module CMORizer
  module Step
    class MERGEFILES < JoinedBaseStep
      def file_commands
        CDO_MERGE_cmd.new        
      end
    end
    
    
    class CMOR_FILE < IndividualBaseStep
    end    
    

    class APPLY_CMOR_FILENAME < IndividualBaseStep
    end
    
    
    class APPLY_GLOBAL_ATTRIBUTES < IndividualBaseStep
        #delete_global_attributes %w(output_schedule history CDO CDI Conventions)
      def file_commands

        builder = GlobalAttributesBuilder.new
        builder.set_experiment_info(id: @experiment.experiment_id,
                                    variant_label: @experiment.variant_label,
                                    first_year: @experiment.first_year)
        parent = @experiment.parent_experiment
        if(parent)
          builder.set_parent_experiment_info(id: parent.experiment_id,
                                      variant_label: parent.variant_label,
                                      first_year: parent.first_year)
        end
        builder.set_variable_info(id: @variable_id, frequency: @frequency, table_id: @table_id, realms: @realms)
        source_id = @experiment.source_id
        builder.set_grid_info(source_id: source_id,
                              nominal_resolution: @experiment.nominal_resolution,
                              txt: @experiment.grid_txt)
    
        ga = builder.build_global_attributes(data_specs_version: @experiment.data_request_version)
        global_attributes = ga.attributes

        # apply global attributes
        NCATTED_ADD_GLOBAL_ATTRIBUTES_cmd.new(global_attributes)
      end
    end
    
    
    class FESOM_MEAN_TIMESTAMP_ADJUST < IndividualBaseStep
      def file_commands
        FESOM_MEAN_TIMESTAMP_ADJUST_cmd.new
      end
    end
    
    
    class Unit_K_to_degC < IndividualBaseStep
    end
    

    class TIME_SECONDS_TO_DAYS < IndividualBaseStep
      def file_commands
        CDO_SET_T_UNITS_DAYS_cmd.new
      end

    end
  end
end
