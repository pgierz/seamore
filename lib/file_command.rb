require 'fileutils'


class FileCommand
  def run(*infiles, outfile)
    execute_atomically(*infiles, outfile, cmd_txt(*infiles, outfile))
  end
  
  
  private
  def execute_atomically(*infiles, outfile, cmd_txt)
    outfile_inprogress = "#{outfile}.inprogress"

    raise "file exists: #{outfile_inprogress}" if File.exist?(outfile_inprogress)
    system_call cmd_txt(infiles, outfile_inprogress)
    
    raise "file exists: #{outfile}" if File.exist? outfile
    FileUtils.mv outfile_inprogress, outfile
  end


  private
  def system_call(cmd)
    t0 = Time.now
    prefix = "#{Thread.current.name}" if Thread.current.name
    puts "#{prefix}=> #{t0.strftime "%H:%M:%S"}  #{cmd}"
    raise cmd unless system cmd
    puts "#{prefix}<= #{sprintf('%5.1f',Time.now-t0)} sec"
  end
end



class CDO_MERGE_cmd < FileCommand
  def cmd_txt(*infiles, outfile)
    %Q(cdo mergetime #{infiles.join(' ')} #{outfile})
  end
end
