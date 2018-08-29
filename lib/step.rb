module CMORizer
  module Step
    class BaseStep
      def execute
        puts "\t#{self.class}"
      end
    end
    
    
    class MERGEFILES < BaseStep
    end
    
    
    class FESOM_MEAN_TIMESTAMP_ADJUST < BaseStep
    end
    
    
    class Unit_K_to_degC < BaseStep
    end
    

    class TIME_SECONDS_TO_DAYS < BaseStep
    end
  end
end
