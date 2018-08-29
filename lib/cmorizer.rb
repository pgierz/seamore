require_relative "step.rb"

module CMORizer
  class Project
    def initialize(src_txt)
      @cmorization_steps_chains = []
      @eval_mode = true
      instance_eval(src_txt, src_txt)
      @eval_mode = false
    end
  
  
    def execute
      @tasks.each {|t| t.execute}
      @cmorization_steps_chains.each do |chain|
      end
    end
  
  
    def experiment_id(*args, &block)
      Experiment.new(*args, &block)
    end


    def cmorize(*args, &block)
      hash = args.first
      src = hash.keys.first
      results = hash.values.first
      results.each do |r|
        @cmorization_steps_chains << StepsChain.new(src, r, &block)
      end
    end


    private
    def method_missing(method_sym, *args, &block)
      return super unless @eval_mode
      method_sym.to_s
    end
  end


  class Experiment
    def initialize(experiment_id, &block)
      @experiment_id = experiment_id # check against controlled vocabularies 
      instance_eval(&block) if block_given?
    end
    
    
    def indir(d)
    end


    def outdir(d)
    end
  end
  
  
  class StepsChain
    def initialize(from, to, &block)
      @fesom_variable_description = from
      @cmor_variable_description = to
      @step_classes = []
      @eval_mode = true
      instance_eval(&block) if block_given?
      @eval_mode = false
      
      # create step instances
      @steps = []
      next_step = nil
      @step_classes.reverse_each do |cls|
        next_step = cls.new(next_step)
        @steps << next_step
      end
      @steps.reverse!
    end
    
    
    def execute
      @steps.each {|s| s.execute}
      puts "#{self.class} #{@fesom_variable_description} ==> #{@cmor_variable_description}"
    end


    def add_step(sym)
      cls = CMORizer::Step.const_get sym
      @step_classes << cls
    end


    def method_missing(method_sym, *args, &block)
      return super unless @eval_mode
      # we assume every unknown method designates a sub-task
      sym = method_sym.upcase
      add_step sym
    end


    def unit(hash)
      from = hash.keys.first
      to = hash.values.first
      sym = "Unit_#{from}_to_#{to}".to_sym
      add_step sym
    end
  end
end


if __FILE__ == $PROGRAM_NAME
  src_txt = <<~'EOFHEREDOC'
  # "fesom name"_"available frequency" => ["variable_id"_"CMIP table_id"]
  cmorize tos_day => [tos_Oday, tos_Omon, tos_Odec]
  cmorize tso_3hrPt => [tos_3hr] do
    unit 'K' => 'degC'
  end
  EOFHEREDOC
  
  project = CMORizer::Project.new src_txt
  project.execute
end
