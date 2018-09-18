require 'fileutils'

module CMORizer
  module Step
    class BaseStep
      attr_writer :forbid_inplace
    
      def initialize(next_step)
        @next_step = next_step
        @available_inputs = {}
        @forbid_inplace = false
      end
      
      
      def set_info(global_attributes:, fesom_variable_name:, variable_id:, description:)
        @global_attributes = global_attributes
        @fesom_variable_name = fesom_variable_name
        @variable_id = variable_id
        @description = description
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
        if @forbid_inplace # bail out if this step is set to not manipulate a file inplace but all FileCommands of this step act inplace
          raise "#{self.class.to_s.split('::').last} is an inplace command" if commands.all? {|c| c.inplace?}
        end
        
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
    
    
    class APPLY_LOCAL_ATTRIBUTES < IndividualBaseStep
      def file_commands
        cmds = []
        # rename our variable
        cmds << NCRENAME_RENAME_VARIABLE_cmd.new(@fesom_variable_name, @variable_id)
        
        # apply description
        cmds << NCATTED_SET_VARIABLE_DESCRIPTION_cmd.new(@variable_id, @description)
        cmds
      end
    end


    class APPLY_GLOBAL_ATTRIBUTES < IndividualBaseStep
      def file_commands
        cmds = []
        cmds << NCATTED_DELETE_GLOBAL_ATTRIBUTES_cmd.new(%w(output_schedule history CDO CDI Conventions))

        global_attributes_hash = @global_attributes.as_hash

        # apply global attributes
        cmds << NCATTED_ADD_GLOBAL_ATTRIBUTES_cmd.new(global_attributes_hash)
        cmds
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
