require 'fileutils'

module CMORizer
  module Step
    class BaseStep
      attr_writer :forbid_inplace, :initial_prefix
      attr_reader :resultpath
    
      def initialize(next_step)
        @next_step = next_step
        @available_inputs = {}
        @forbid_inplace = false
        @initial_prefix = nil
        @resultpath = nil
      end
      
      
      def set_info(outdir:, grid_description_file:, global_attributes:, fesom_variable_name:, fesom_variable_frequency:, variable_id:, description:)
        @outdir = outdir
        @grid_description_file = grid_description_file
        @global_attributes = global_attributes
        @fesom_variable_name = fesom_variable_name
        @fesom_variable_frequency = fesom_variable_frequency
        @variable_id = variable_id
        @description = description
      end


      def add_input(input, years, number_of_eventual_input_years, should_process)
        @available_inputs[years] = input
        
        # some steps might be able to process each file as soon as it arrives
        # others, like merge, might require the maximum number of files to be available
        if can_process?(number_of_eventual_input_years)
          sorted_years_arrays = @available_inputs.keys.sort
          sorted_inputs = @available_inputs.values_at(*sorted_years_arrays)

          sorted_years = sorted_years_arrays.flatten
          @resultpath = create_outpath(*sorted_inputs)
          process(sorted_inputs, sorted_years, @resultpath) if should_process
          results, result_years = [@resultpath], sorted_years
          
          if results && @next_step
            results.each_index do |i|
              @next_step.add_input(results[i], [result_years[i]], number_of_eventual_input_years, should_process)
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
        
        unless File.exist? opath # only run this step if its output does not already exist
          command_inputs = inputs
          command_opath = nil
          commands.each_with_index do |cmd, i|
            command_opath = "#{opath}.#{i}"
            cmd.run(command_inputs, command_opath)
            command_inputs = [command_opath]
          end
        
          if command_opath # i.e. commands array is empty
            FileUtils.mv command_opath, opath
          else
            raise "can not rename multiple inputs to a single output" if inputs.size > 1
            FileUtils.mv inputs[0], opath
          end          
        end
      end
            
      
      def file_commands
        raise "overwrite with concrete implementation for #{self.class} which returns one or many FileCommand objects"
      end
      
      
      def create_outpath(*inpaths)
        step_suffix = self.class.to_s.split('::').last
        step_suffix = step_suffix[0..9] # truncate to 10 characters so we do not get too long file names (apparently 255 chars max on mistral)
        prefix = (@initial_prefix) ? "#{@initial_prefix}" : ""
        from = "#{File.basename(inpaths[0])}"
        to = (inpaths.size > 1) ? "-#{File.basename(inpaths.last)}" : ""
        
        outname = "#{prefix}#{from}#{to}.#{step_suffix}"
        
        File.join @outdir, outname
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
    
    
    class AUTOMATICALLY_DOWNSAMPLE_FREQUENCY < IndividualBaseStep
      def file_commands
        cmds = []
        
        in_freq = Frequency.for_name(@fesom_variable_frequency)
        out_freq = Frequency.for_name(@global_attributes.frequency)

        if(in_freq != out_freq)          
          case [in_freq.name, out_freq.name]
          when ["day", "mon"]
            # cdo monmean day_file mon_file
            cmds << CDO_MONMEAN_cmd.new
          else
            raise "can not automatically downsample frequency from '#{in_freq.name}' to '#{out_freq.name}'"
          end
        end
        
        cmds
      end
    end
    
    
    class CMOR_FILE < IndividualBaseStep
    end    
    

    class APPLY_CMOR_FILENAME < IndividualBaseStep
      def create_outpath(*inpaths)
        raise "can not create CMOR filename for multiple inputs" if inpaths.size > 1
        outname = @global_attributes.filename
                
        File.join @outdir, outname
      end
      
      def file_commands
        []
      end
    end
    
    
    class APPLY_GRID < IndividualBaseStep
      def file_commands
        cmds = []
        cmds << NCRENAME_DIMENSION_NODES_XD_TO_NCELLS_cmd.new
        cmds << NCKS_APPEND_GRID_cmd.new(@grid_description_file)
        cmds << NCATTED_APPEND_COORDINATES_VALUE_cmd.new(@variable_id)
        cmds
      end
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


    class FIX_CF_NAMES < IndividualBaseStep
      def file_commands
        cmds = []
        cmds << NCATTED_SET_LAT_LON_BNDS_STANDARD_NAME_cmd.new
        cmds << NCATTED_DELETE_VARIABLE_ATTRIBUTES_cmd.new("lat_bnds", %w(units standard_name centers))
        cmds << NCATTED_DELETE_VARIABLE_ATTRIBUTES_cmd.new("lon_bnds", %w(units standard_name centers))
        cmds
      end
    end
    
    
    class MEAN_TIMESTAMP_ADJUST < IndividualBaseStep
      def file_commands
        MEAN_TIMESTAMP_ADJUST_cmd.new
      end
    end
    
    
    class INSERT_TIME_BOUNDS < IndividualBaseStep
      def file_commands
        INSERT_TIME_BOUNDS_cmd.new
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
