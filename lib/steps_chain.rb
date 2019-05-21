module CMORizer
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
    end
    
    
    def to_s
      "#{@input_variable_name}_#{@input_frequency_name} ==> #{@cmor_variable_id}_#{@cmor_table_id}"
    end
    
    
    def execute(fesom_files, experiment, data_request, grid_description_file, version_date)      
      return if @step_classes.empty?
      
      # create new step instances here for each call to execute to have this method thread safe
      steps = []
      next_step = nil
      @step_classes.reverse_each do |cls|
        next_step = cls.new(next_step)
        steps << next_step
      end
      steps.reverse!
      unless steps.empty?
        steps[0].forbid_inplace = true # do not modify the original input files
        steps[0].initial_prefix = "_#{@input_variable_name}_#{@input_frequency_name}--#{@cmor_variable_id}_#{@cmor_table_id}_"
      end
            
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
      
      steps.each {|s| s.set_info(outdir: experiment.outdir,
                                  grid_description_file: grid_description_file,
                                  global_attributes: global_attributes,
                                  fesom_variable_name: @input_variable_name,
                                  fesom_variable_frequency: @input_frequency_name,
                                  fesom_unit: fesom_files.first.unit,
                                  out_unit: data_request_variable.unit,
                                  variable_id: data_request_variable.variable_id,
                                  description: data_request_variable.description,
                                  standard_name: data_request_variable.standard_name,
                                  cell_methods: data_request_variable.cell_methods)}
    
      # fill the first step with all the passed files without executing (i.e. dry run)
      # this will set the resultpath for each step
      fesom_files.each do |f|
        steps.first.add_input(f.path, [f.year], fesom_files.size, false)
      end
      
      # check from which resultpath we can resume this StepsChain (i.e. from the last resultpath for which a file exists)
      last_existing_index = -1
      steps.each_with_index do |step,i|
        last_existing_index = i if File.exist?(step.resultpath)
      end
      # set all steps which result in the last file we have available to skip execution
      steps.each_with_index do |step,i|
        step.needs_to_run = (last_existing_index < i)
      end     
      
      # fill the steps to execute from first to last step
      fesom_files.each do |f|
        steps.first.add_input(f.path, [f.year], fesom_files.size, true)
      end

      # remove all step results except the last one, we did set steps[0].forbid_inplace = true, so the first step has created a copy of the original input
      if(File.exist? steps.last.resultpath)
        steps[0..-2].each do |s|
          FileUtils.rm(s.resultpath) if File.exist?(s.resultpath) # if the step processes all files inplace, the resultpath from the previous step has been renamed and does not exist anymore
        end
      end
    end
    
    
    private def create_global_attributes(experiment:, first_file_year:, last_file_year:, variable_id:, frequency:, table_id:, realms:, version_date:)
      builder = GlobalAttributesBuilder.new
      builder.set_experiment_info(id: experiment.experiment_id,
                                  source_id: experiment.source_id,
                                  activity_id: experiment.activity_id,
                                  variant_label: experiment.variant_label,
                                  first_year: first_file_year,
                                  last_year: last_file_year)
      parent_info = experiment.parent_experiment_info
      if(parent_info)
        builder.set_parent_experiment_info(id: parent_info.experiment_id,
                                    source_id: parent_info.source_id,
                                    activity_id: parent_info.activity_id,
                                    variant_label: parent_info.variant_label,
                                    first_year: parent_info.first_year,
                                    branch_year: parent_info.branch_year)
      end
      builder.set_variable_info(id: variable_id, frequency: frequency, table_id: table_id, realms: realms)
      builder.set_grid_info(nominal_resolution: experiment.nominal_resolution,
                            txt: experiment.grid_txt)
  
      builder.build_global_attributes(version_date: version_date, data_specs_version: experiment.data_request_version)
    end


    private def add_step(sym)
      cls = CMORizer::Step.const_get sym
      @step_classes << cls
    end


    def method_missing(method_sym, *args, &block)
      return super unless @eval_mode
      # we assume every unknown method designates a sub-task
      sym = method_sym.upcase
      add_step sym
    end
  end
end
