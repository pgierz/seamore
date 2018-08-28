require_relative "step.rb"

module CMORizer
  class Project
    def initialize(src_txt)
      instance_eval(src_txt, src_txt)
    end
  
  
    def cmorize(*args, &block)
      hash = args.first
      src = hash.keys.first
      results = hash.values.first
      results.each do |r|
        Task.new(src, r, &block)
      end
    end


    private
    def method_missing(method_sym, *args, &block)
      method_sym.to_s
    end


    def self.const_missing(name)
      name.to_s
    end
  end


  class Task
    def initialize(src, result, &block)
      puts "#{self.class} #{src} ==> #{result}"
      @src = src
      @result = result
      instance_eval(&block) if block_given?
    end


    def method_missing(method_sym, *args, &block)
      # we assume every unknown method designates a sub-task
      hash = args.first
      from = hash.keys.first
      to = hash.values.first
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
  
  CMORizer::Project.new src_txt
end
