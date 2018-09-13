require_relative "step.rb"
require_relative "controlled_vocabularies.rb"
require_relative "fesom_output_dir.rb"


module CMORizer
  class Project
    def initialize(src_txt)
      @cmorization_steps_chains = []
      @experiments = []
      @years_step = 1
      @eval_mode = true
      instance_eval(src_txt, src_txt)
      @eval_mode = false
    end
    
  
    def execute
      @experiments.each do |experiment|
        experiment_year_ranges = Project.year_ranges(first: experiment.first_year.to_i, last: experiment.last_year.to_i, step: @years_step)
        fesom_output_files = FesomOutputDir.new(experiment.indir).variable_files
        
        @cmorization_steps_chains.each do |chain|
          experiment_year_ranges.each do |year_range|

            # fetch files for chain.fesom_variable_description + year_range
            filtered_fesom_files =
              fesom_output_files.select do |ff|
                if year_range.first <= ff.year && ff.year <= year_range.last
                  if ff.variable_id == chain.fesom_variable_name && ff.frequency == chain.fesom_available_frequency
                    true
                  end
                end
              end

            chain.execute(filtered_fesom_files, experiment, @data_request) unless filtered_fesom_files.empty?
          end        
        end
      end
    end
  
  
    def cmip6_cmor_tables(version, dir)
      @data_request = DataRequest.new_from_tables_dir(File.expand_path dir)
      raise "data request at #{dir} has version #{@data_request.version} but requested version is #{version}" unless version == @data_request.version
    end
  
  
    def cmip6_cvs_dir(d) # DSL setter
      d = File.expand_path d
      @controlled_vocabularies = ControlledVocabularies.new_from_dir d
    end
    
    
    def merge_years_step(s) # DSL setter
      @years_step = s
    end
    
    
    def source_id(id) # DSL setter
      @source_id = id
    end


    def experiment_id(*args, &block)
      @experiments << Experiment.new(@source_id, args.shift, @data_request.version, @controlled_vocabularies, &block)
    end
  
  
    # "fesom name"_"available frequency" => ["variable_id"_"CMIP table_id"]
    def cmorize(*args, &block)
      hash = args.first
      src = hash.keys.first
      results = hash.values.first
      results.each do |r|
        @cmorization_steps_chains << StepsChain.new(src, r, &block)
      end
    end
    
    
    def self.year_ranges(first:, last:, step:)
      # this looks too complicated, but I am tired and it passes the tests
      ranges = []
      range_first = first
      range_last = first+step-1
      while range_last <= last do
        ranges << [range_first, range_last]
        range_first += step
        range_last += step
      end
      if(range_first <= last && range_last > last)
        ranges << [range_first, last]
      end
      ranges
    end


    private
    def method_missing(method_sym, *args, &block)
      return super unless @eval_mode
      method_sym.to_s
    end
  end


  class Experiment
    attr_reader :variant_label, :source_id, :nominal_resolution, :grid_txt, :data_request_version
    
    def initialize(source_id, experiment_id, data_request_version, controlled_vocabularies, &block)
      @source_id = source_id
      @experiment_id = experiment_id
      @data_request_version = data_request_version
      @experiment_cv = controlled_vocabularies['experiment_id'][@experiment_id]
      raise "experiment_id #{@experiment_id} does not exist in controlled vocabularies" unless @experiment_cv
      instance_eval(&block) if block_given?
      @variant_label = "r1i1p1f002"
      @nominal_resolution = controlled_vocabularies['source_id'][source_id]['model_component']['ocean']['native_nominal_resolution']
      @grid_txt = controlled_vocabularies['source_id'][source_id]['model_component']['ocean']['description']
    end
    
    
    def indir(d)
      @indir = File.expand_path d # DSL setter
      def self.indir # redefine to behave as getter
        @indir
      end
    end


    def outdir(d)
      @outdir = File.expand_path d # DSL setter
      def self.outdir # redefine to behave as getter
        @outdir
      end
    end


    def parent_experiment(pe=nil) # optinal DSL setter
      @parent_experiment = pe
      def self.parent_experiment # redefine to behave as getter
        @parent_experiment
      end
      @parent_experiment
    end


    def first_year
      start_year
    end


    def last_year
      end_year
    end


    def method_missing(method_sym, *args, &block)
      return super if (!args.empty? && !block_given?)
      # we assume we should get a key from our CV hash
      if @experiment_cv.has_key? method_sym.to_s
        return @experiment_cv[method_sym.to_s]
      else
        super # not a hash key, so treat as a non-existing method
      end
    end
  end
  
  
  class StepsChain
    attr_reader :fesom_variable_name, :fesom_available_frequency
    
    # fesom_variable_description: "fesom name"_"available frequency"
    # cmor_variable_description: "variable_id"_"CMIP table_id"
    def initialize(fesom_variable_description, cmor_variable_description, &block)
      @fesom_variable_name, @fesom_available_frequency = fesom_variable_description.split('_')
      @cmor_variable_id, @cmor_table_id = cmor_variable_description.split('_')

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
    
    
    def execute(fesom_files, experiment, data_request)
      puts "#{@fesom_variable_name}_#{@fesom_available_frequency} ==> #{@cmor_variable_id}_#{@cmor_table_id}"
      
      # offer info about the current experiment and variable to all step objects
      data_request_variable = data_request.find @cmor_variable_id
      frequency = data_request_variable.frequency_in_table(@cmor_table_id)
      @steps.each {|s| s.set_info(experiment: experiment,
                                  variable_id: data_request_variable.variable_id,
                                  frequency: frequency,
                                  table_id: @cmor_table_id,
                                  realms: data_request_variable.realms)}
      
      # fill the first step with all the passed files
      fesom_files.each do |f|
        @steps.first.add_input(f.path, [f.year], fesom_files.size)
      end
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
