require_relative "step.rb"
require_relative "controlled_vocabularies.rb"
require_relative "fesom_output_dir.rb"
require_relative "global_attributes.rb"
require 'fileutils'


module CMORizer
  class Project
    def initialize(src_txt)
      @default_step_classes = []
      @cmorization_steps_chains = []
      @experiments = []
      @years_step = 1
      @eval_mode = true
      instance_eval(src_txt, src_txt)
      @eval_mode = false
    end
    
  
    def execute
      @experiments.each do |experiment|
        fesom_output_files = FesomOutputDir.new(experiment.indir).variable_files
        # sort the fesom files
        fesom_output_files = fesom_output_files.sort_by {|ff| "#{ff.variable_id}#{ff.year}"}

        if(experiment.first_year)
          first_year = experiment.first_year
        else
          # no year given in experiment, search for the lowest year in all files
          first_year = (fesom_output_files.min {|a,b| a.year <=> b.year}).year
        end

        if(experiment.last_year)
          last_year = experiment.last_year
        else
          # no year given in experiment, search for the highest year in all files
          last_year = (fesom_output_files.max {|a,b| a.year <=> b.year}).year
        end
        experiment_year_ranges = Project.year_ranges_major_digits(first: first_year.to_i, last: last_year.to_i, step: @years_step, major_first_digit:1)
        
        threadcount = 20
        threads = []
        chains_queue = Queue.new
        @cmorization_steps_chains.each {|chain| chains_queue << chain}

        threadcount.times do
          threads << Thread.new(threads.size) do |threadname|
            Thread.current.name = "T#{threadname}"
        
            didanything = false
            while !chains_queue.empty?
              chain = chains_queue.pop
              execute_chain(chain, experiment, experiment_year_ranges, fesom_output_files)
              didanything = true
            end
            
            puts "#{Thread.current.name}: => #{Time.now} DONE <=" if didanything
          end
        end

        threads.each(&:join)
        threads.clear
      end
    end


    private def execute_chain(chain, experiment, experiment_year_ranges, fesom_output_files)
      experiment_year_ranges.each do |year_range|

        # fetch files for chain.fesom_variable_description + year_range
        filtered_fesom_files =
          fesom_output_files.select do |ff|
            if year_range.first <= ff.year && ff.year <= year_range.last
              if ff.variable_id == chain.input_variable_name && ff.frequency == chain.input_frequency_name
                true
              end
            end
          end

        chain.execute(filtered_fesom_files, experiment, @data_request, @grid_description_file, @version_date) unless filtered_fesom_files.empty?
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
    
    
    def version_date(y,m,d) # DSL setter
      @version_date = [y,m,d]
    end
    
    
    def source_id(id) # DSL setter
      @source_id = id
    end
  
  
    def grid_description_file(f) # DSL setter
      f = File.expand_path f
      raise "grid description file not readable: #{f}" unless File.readable?(f)
      @grid_description_file = f
    end


    def experiment_id(*args, &block)
      @experiments << Experiment.new(@source_id, args.shift, @data_request.version, @controlled_vocabularies, &block)
    end


    def cmorize_defaults(*args, &block)
      evaluater = Object.new
      def evaluater.method_missing(method_sym, *args, &block)
        # we assume every unknown method designates a default step
        sym = method_sym.upcase
        @default_steps ||= []
        @default_steps << sym
      end
      def evaluater.default_steps
        @default_steps
      end
      evaluater.instance_eval(&block)
      @default_step_classes = evaluater.default_steps.map {|sym| CMORizer::Step.const_get sym}
    end
  
  
    # "fesom name"_"available frequency" => ["variable_id"_"CMIP table_id"]
    def cmorize(*args, &block)
      hash = args.first
      src = hash.keys.first
      results = hash.values.first
      results.each do |r|
        @cmorization_steps_chains << StepsChain.new(@default_step_classes, src, r, &block)
      end
    end
    
    
    # generate year ranges, but prefer to start with the given major digit
    # i.e. if the major first digit is 1 and step is 10, we could get the ranges 50-50,51-60,61-70,71-72
    # if the major first digit is 0 and step is 10, we could get the ranges      50-59,60-69,70-72
    def self.year_ranges_major_digits(first:, last:, step:, major_first_digit:)
      raise "not a single digit: #{major_first_digit}" if major_first_digit.to_s.chars.size != 1
      
      first_digit = first.to_s.chars.last.to_i
      major_first = first + major_first_digit - first_digit
      major_first += 10 if major_first < first

      if(first < major_first)
        ranges = year_ranges(first: first, last: major_first-1, step: step)
        ranges.concat year_ranges(first: major_first, last: last, step: step)
      end
      
      ranges
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

    
    def variant_label(l) # DSL setter
      @variant_label = l
      def self.variant_label # redefine to behave as getter
        @variant_label
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
      if start_year.empty?
        nil # some experiment_id controlled vocabularies do not have a start_year, e.g. control-1950
      else
        start_year
      end
    end


    def last_year
      if end_year.empty?
        nil # some experiment_id controlled vocabularies do not have a end_year, e.g. control-1950
      else
        end_year
      end
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
    attr_reader :input_variable_name, :input_frequency_name
    
    # fesom_variable_description: "fesom name"_"available frequency"
    # cmor_variable_description: "variable_id"_"CMIP table_id"
    def initialize(default_step_classes, fesom_variable_description, cmor_variable_description, &block)
      @input_variable_name, @input_frequency_name = fesom_variable_description.split('_')
      @cmor_variable_id, @cmor_table_id = cmor_variable_description.split('_')

      @step_classes = []
      @eval_mode = true
      instance_eval(&block) if block_given?
      @eval_mode = false
            
      @step_classes = default_step_classes if @step_classes.empty?
      
      # create step instances
      @steps = []
      next_step = nil
      @step_classes.reverse_each do |cls|
        next_step = cls.new(next_step)
        @steps << next_step
      end
      @steps.reverse!
      unless @steps.empty?
        @steps[0].forbid_inplace = true # do not modify the original input files
        @steps[0].initial_prefix = "_#{@input_variable_name}_#{@input_frequency_name}--#{@cmor_variable_id}_#{@cmor_table_id}_"
      end
    end
    
    
    def execute(fesom_files, experiment, data_request, grid_description_file, version_date)
      puts "#{@input_variable_name}_#{@input_frequency_name} ==> #{@cmor_variable_id}_#{@cmor_table_id}"
            
      # offer info about the current experiment and variable to all step objects
      data_request_variable = data_request.find_variable_id_in_table_id(@cmor_variable_id, @cmor_table_id) # the variable from the data request might have a different frequency than the input variable
      raise "data request does not contain variable #{@cmor_variable_id} #{@input_frequency_name}" unless data_request_variable
      cmor_frequency_name = data_request_variable.frequency_in_table(@cmor_table_id)
      global_attributes = create_global_attributes(experiment: experiment,
                                          first_file_year: fesom_files.first.year,
                                          last_file_year: fesom_files.last.year,
                                          variable_id: data_request_variable.variable_id,
                                          frequency: cmor_frequency_name,
                                          table_id: @cmor_table_id,
                                          realms: data_request_variable.realms,
                                          version_date: version_date)
      
      @steps.each {|s| s.set_info(outdir: experiment.outdir,
                                  grid_description_file: grid_description_file,
                                  global_attributes: global_attributes,
                                  fesom_variable_name: @input_variable_name,
                                  fesom_variable_frequency: @input_frequency_name,
                                  variable_id: data_request_variable.variable_id,
                                  description: data_request_variable.description)}
    
      # fill the first step with all the passed files without executing
      fesom_files.each do |f|
        @steps.first.add_input(f.path, [f.year], fesom_files.size, false)
      end
      # if the resultpath of the last step (i.e. the final path) does not exist, execute the steps
      unless(File.exist? @steps.last.resultpath)
        fesom_files.each do |f|
          @steps.first.add_input(f.path, [f.year], fesom_files.size, true)
        end

        # remove all step results except the last one, we did set @steps[0].forbid_inplace = true, so the first step has created a copy of the original input
        if(File.exist? @steps.last.resultpath)
          @steps[0..-2].each do |s|
            FileUtils.rm(s.resultpath) if File.exist?(s.resultpath) # if the step processes all files inplace, the resultpath from the previous step has been renamed and does not exist anymore
          end
        end
      end
    end
    
    
    private def create_global_attributes(experiment:, first_file_year:, last_file_year:, variable_id:, frequency:, table_id:, realms:, version_date:)
      builder = GlobalAttributesBuilder.new
      builder.set_experiment_info(id: experiment.experiment_id,
                                  source_id: experiment.source_id,
                                  variant_label: experiment.variant_label,
                                  first_year: first_file_year,
                                  last_year: last_file_year)
      parent = experiment.parent_experiment
      if(parent)
        builder.set_parent_experiment_info(id: parent.experiment_id,
                                    source_id: experiment.source_id,
                                    variant_label: parent.variant_label,
                                    first_year: parent.first_year)
      end
      builder.set_variable_info(id: variable_id, frequency: frequency, table_id: table_id, realms: realms)
      builder.set_grid_info(nominal_resolution: experiment.nominal_resolution,
                            txt: experiment.grid_txt)
  
      builder.build_global_attributes(version_date: version_date, data_specs_version: experiment.data_request_version)
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
