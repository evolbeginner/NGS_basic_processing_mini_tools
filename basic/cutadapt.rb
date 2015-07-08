#! /bin/env ruby

# apply Cutadapt to sequences trimming free to use
# created by Sishuo Wang (sishuowang@hotmail.ca) from the Department of Botany, the University of British Columbia


###################################################
require 'getoptlong'

def auto_output_name(input_name)
  output_name="STDOUT"
  output_name = $1+".cutadapt"+$2 if File.basename(input_name) =~ /(.+)(\.[^.]+)$/
  return(output_name)
end


def guess_fastq_format(input,fastq_detect)
  return_value="Phred33"
  lines=IO.popen("perl #{fastq_detect} #{input} 1000").readlines
  lines.each do |line|
    if line =~ /  Illumina 1\.(3|5|13)\+\s+:  x/ or line =~ /  Solexa[ ]+:  x/
      return_value="Phred64"
    end
  end
  return return_value
end


def mkdir_with_force(outdir,force=false)
  if ! Dir.exists?(outdir)
    `mkdir -p #{outdir}`
  else
    if force
      if outdir != './' and outdir != '.'
        `rm -rf #{outdir}`
        `mkdir -p #{outdir}`
      end
    else
      raise "The outdir #{outdir} has already existed!"
    end
  end
end


def show_help(help_message=nil)
  puts help_message if help_message
  puts "Usage: ruby #{File.basename($0)} <-i|--input=> <--args=> [options]"
  puts <<EOF
Options:
  --cutadapt         path of the executable file of cutadapt
  -i|--input         input_file
  -o|--output        output_file, use STDOUT or '-' to indicate STDOUT
  --auto_output_name automatically name outputs
                     e.g. if the name of the input file is 1.fq, the output file will be named as 1.trimmed.fq automatically
EOF
  puts
  exit
end


###################################################
cutadapt="/mnt/bay3/sswang/software/NGS/basic_processing/cutadapt-1.4.1/bin/cutadapt"
fastq_detect="/mnt/bay3/sswang/software/NGS/basic_processing/mini_tools/fastq_detect.pl"
args_content=nil
outputs=Array.new
inputs=Array.new
outdir='./'
is_auto_output_name=false
force=false


ARGV.empty? && show_help("No arguments!")
opts = GetoptLong.new(
  ['--cutadapt',GetoptLong::REQUIRED_ARGUMENT],
  ['--args',GetoptLong::REQUIRED_ARGUMENT],
  ['-i','--input',GetoptLong::REQUIRED_ARGUMENT],
  ['-o','--output',GetoptLong::REQUIRED_ARGUMENT],
  ['-d','--outdir',GetoptLong::REQUIRED_ARGUMENT],
  ['--auto_output_name',GetoptLong::NO_ARGUMENT],
  ['--force',GetoptLong::NO_ARGUMENT],
  ['-h','--help',GetoptLong::NO_ARGUMENT],
)


opts.each do |opt,value|
  case opt
    when '--cutadapt'
      cutadapt=File.expand_path(value)
    when '--args'
      if value == "no_args"
        ;
      elsif value !~ /:/
        args_content=value
      else
        args_contents = Array.new
        value.split(',').each do |arg|
          arg.gsub!(":"," ")
          arg="-"+arg if arg !~ /^[-]/
          args_contents.push(arg)
        end
        args_content = args_contents.join(" ")
      end
    when '-i', '--input'
      inputs.push value
    when '-o', '--out'
      outputs.push value
    when '-d', '--outdir'
      outdir=value
    when '--auto_output_name'
      is_auto_output_name=true
    when '--force'
      force=true
    when '-h','--help'
      show_help()
  end
end


if outputs.empty?
  is_auto_output_name=true
end

if is_auto_output_name
  inputs.map{|file| outputs.push(auto_output_name(file))}
end


args_content.nil? and show_help("arguments need to be specified by --args")
inputs.empty? and show_help("inputs cannot be empty!")
mkdir_with_force(outdir,force)

'''
outputs.map!{|i|
  if i =~ /^(\-|STDOUT)$/
    i
  else
    File.join(outdir,i)
  end
}
'''


###################################################
inputs.each_with_index do |input,index|
  if File.exists?(fastq_detect) then
    if guess_fastq_format(input,fastq_detect) == "Phred64"
      args_content += " --quality-base 64"
    end
  end
  output=outputs[index]
  if output == "STDOUT" or output == '-'
    puts "#{cutadapt} #{args_content} #{input}"
    system("#{cutadapt} #{args_content} #{input}")
  else
    fh=File.open(output+'.args','w')
    fh.puts [File.basename(input),args_content].join("\t")
    `#{cutadapt} #{args_content} #{input} > #{output}`
  end
end


