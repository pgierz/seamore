require_relative "../lib/file_command.rb"

require "minitest/autorun"


class GEMDependenciesTests < Minitest::Test
  def test_can_load_gli_gem
    require 'gli'
  end
end


class SystemCLICommandsDependenciesTests < Minitest::Test  

  # create a test method for all known system commands  
  SYSTEM_COMMANDS::ALL.each do |cmd_name|
    define_method("test_command_#{cmd_name}_exists".to_sym) do
      
      capture_subprocess_io do
        puts "Checking if command exists: #{cmd_name}"
        cmd_txt = system("command -v #{cmd_name}")
        puts "Output: #{cmd_txt}"
        raise  "failed: #{cmd_txt}" unless system(cmd_txt)
      end
    
    end
  end

end
