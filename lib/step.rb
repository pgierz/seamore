require_relative "processable_file.rb"


module CMORizer
  module Step
    class BaseStep
      def execute
        puts "\t#{self.class}"
      end
    

      def initialize(next_step)
        @next_step = next_step
        @available_inputs = {}
      end


      def add_input(input, years, number_of_eventual_input_years)
        @available_inputs[years] = input
        
        # some steps might be able to process each file as soon as it arrives
        # others, like merge, might require the maximum number of files to be available
        if can_process?(number_of_eventual_input_years)
          sorted_years_arrays = @available_inputs.keys.sort
          sorted_inputs = @available_inputs.values_at(*sorted_years_arrays)

          sorted_years = sorted_years_arrays.flatten
          results, result_years = process(sorted_inputs, sorted_years)
          
          if results && @next_step
            results.each_index do |i|
              @next_step.add_input(results[i], [result_years[i]], number_of_eventual_input_years)
            end
          end
          @available_inputs.clear
        end
      end
            
      
      def process(inputs, years)
        puts "\t#{self.class} #{inputs.map{|f| File.basename(f.path)}.join(', ')}"
        return inputs, years
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


module CMORizer
  module Step
    class MERGEFILES < JoinedBaseStep
    end
    
    
    class CMOR_FILE < IndividualBaseStep
    end    
    

    class APPLY_CMOR_FILENAME < IndividualBaseStep
    end


    class APPLY_GLOBAL_ATTRIBUTES < IndividualBaseStep
    end
    
    
    class FESOM_MEAN_TIMESTAMP_ADJUST < IndividualBaseStep
    end
    
    
    class Unit_K_to_degC < IndividualBaseStep
    end
    

    class TIME_SECONDS_TO_DAYS < IndividualBaseStep
    end
  end
end
