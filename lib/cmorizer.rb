require_relative "step.rb"

module CMORizer
  class Project
    def initialize(src_txt)
      @tasks = []
      instance_eval(src_txt, src_txt)
    end
  
  
    def execute
      @tasks.each {|t| t.execute}
    end
  
  
    def cmorize(*args, &block)
      hash = args.first
      src = hash.keys.first
      results = hash.values.first
      results.each do |r|
        @tasks << Task.new(src, r, &block)
      end
    end


    private
    def method_missing(method_sym, *args, &block)
      method_sym.to_s
    end
  end


  class Task
    def initialize(from, to, &block)
      @fesom_variable = from
      @cmor_variable = to
      @steps = []
      @eval_mode = true
      instance_eval(&block) if block_given?
      @eval_mode = false
    end
    
    
    def execute
      puts "#{self.class} #{@fesom_variable} ==> #{@cmor_variable}"
      @steps.each {|s| s.execute}
    end


    def method_missing(method_sym, *args, &block)
      return super unless @eval_mode
      # we assume every unknown method designates a sub-task
      sym = method_sym.upcase
      cls = CMORizer::Step.const_get sym
      @steps << cls.new
    end


    def unit(hash)
      from = hash.keys.first
      to = hash.values.first
      sym = "Unit_#{from}_to_#{to}".to_sym
      cls = CMORizer::Step.const_get sym
      obj = cls.new
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
