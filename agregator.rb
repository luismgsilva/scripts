require 'terminal-table'
require 'json'

require_relative "#{__FILE__}/../lib/table.rb"
require_relative "#{__FILE__}/../lib/rules.rb"

def helper()
  puts <<-EOF

Usage: ruby <script_name.rb> [options...]

Global options:
  --help                         Print usage and exit.

  -f  | --file                   Specify the json file.

  -v  | --verbose                Enable verbose mode.

  -vv                            Specify verbose filter and enable verbose mode.
                                 ( npass | nfail | atest | rtest | passfail | failpass )

  -o  | --output                 Specify output mode.
                                 ( json | text | html )
  EOF
  exit()
end

#if ARGV.length < 1
#  helper()
#end


#to_json do |opts|
#  puts JSON.pretty_generate @ret
#end

#to_text do |opts|
#  data = {}
#  table = create_table(@ret, data, opts, @filter)
#  puts table
#  print_compare(data) if @verbose
#end

#to_html do |opts|
#  data = {}
#  compare_html = nil
#  table = create_table(@ret, data, opts, @filter)
#  compare_html = generate_compare_html(data) if @verbose
#  table_html = convert_table_html(table, compare_html)
#  puts table_html
#end

#process_opts1 do |opts|
#  while opts.any?
#    case opts.shift
#    when "--help"
#      helper()
#    when "-f", "--file"
#      @ret =JSON.parse(File.read(opts.shift))
#    when "-v", "--verbose"
#      @verbose = true
#    when "-vv"
#      tmp = opts.shift
#      if !(%w[npass nfail atest rtest passfail failpass] & [tmp]).any?
#        abort("ERROR: Option not valid")
#      end
#      @verbose = true
#      @filter ||= []
#      @filter << tmp
#    end
#  end
#end

#set_default(:text)

#execute()

def option_parser(argv)
  options = {}

  while argv.any?
    case argv.shift
    when "--help"
      help()
    when "--send-email"
      options[:send_email] = argv.shift
    when "-o", "--output"
      options[:output] = argv.shift
    when "-f", "--file"
      @ret =JSON.parse(File.read(argv.shift))
    when "-t", "--target"
      options[:target] = argv.shift
    when "-v", "--verbose"
      options[:verbose] = true
    when "-vv"
      opt = argv.shift
      if !(%w[npass nfail atest rtest passfail failpass] & [opt]).any?
        abort("error: Option not valid")
      end

      options[:verbose] = true
      options[:filter] ||= []
      options[:filter] << opt
    end
  end

  return options
end

def generate_json(options)
  str = JSON.pretty_generate @ret
  return str
end

def generate_text(options)
  data = {}
  table = create_table(@ret, data, options, options[:filter])
  puts table
  if options[:verbose]
    str = print_compare(data)
  end
  return str
end

def generate_html(options)
  data = {}
  compare_html = nil
  table = create_table(@ret, data, options, options[:filter])
  if options[:verbose]
    compare_html = generate_compare_html(data)
  end
  str = convert_table_html(table, compare_html)

  return str 
end

def generate_email(result, options)

  if options[:output] != "html"
    data = {}
    table = create_table(@ret, data, options, options[:filter])
    if options[:verbose]
      compare_html = generate_compare_html(data)
    end
    result = convert_table_html(table, compare_html)
  end

  temp_file = `mktemp`.chomp
  File.write(temp_file, result)
  recipients = options[:send_email]

  script_path = File.join(__dir__, "lib", "my_email.py")
  system("python3 #{script_path} #{recipients} -f #{temp_file}")
  #puts("python3 #{script_path} #{recipients} -f #{temp_file}")
end

def main(argc, argv)
  if argc < 1
    help()
  end

  options = option_parser(argv)
  
  output_format = options[:output] || "text"
  result = case output_format
           when "text"
             generate_text(options)
           when "json"
             generate_json(options)
           when "html"
             generate_html(options)
           when "email"
             generate_email(options)
           else
             abort("error: Output format invalid")
           end

  

  puts(result)

  if options[:send_email]
    generate_email(result, options)
  end
end

if __FILE__ == $PROGRAM_NAME
  main(ARGV.length, ARGV)
end
