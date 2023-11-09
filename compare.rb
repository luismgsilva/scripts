require 'terminal-table'
require 'json'

require_relative "#{__FILE__}/../lib/table.rb"
require_relative "#{__FILE__}/../lib/rules.rb"

FAILING_SENARIOS = ["FAIL", "UNSUPPORTED", "XPASS", "UNRESOLVED"]
PASSING_SENARIOS = ["PASS", "XFAIL"]
@filters = {}
def parse_sum(filename)
  # valid_results = ['PASS', 'FAIL', 'XFAIL', 'XPASS', 'UNRESOLVED', 'UNSUPPORTED']
  valid_results = FAILING_SENARIOS + PASSING_SENARIOS
  content = File.read(filename)
  data = {}
  content.each_line do |l|
    if(l =~ /([A-Z]+): (.+)/)
      if(data[$2] == nil)
        data[$2] = $1 if(valid_results.include?($1))
      elsif(valid_results.include?($1))
        count = 1
        tmp = "#{$2} (#{count})"
        while(data[tmp] != nil)
          count += 1
          tmp = "#{$2} (#{count})"
        end
        data[tmp] = data[$2] = $1
      end
    end
  end
  return data
end



@ret = {
  changes: {
    new_fail: {},
    new_pass: {},
    add_test: {},
    rem_test: {}
    },

  baseline_results: {
    pass: 0,
    fail: 0,
    not_considered: 0
  },
  results: {
    pass: 0,
    fail: 0,
    not_considered: 0
  },
  results_delta: {
    new_fail: 0,
    new_pass: 0,
    add_test: 0,
    rem_test: 0
  },
  filtered_results: {
    changes: {
      new_fail: {},
      new_pass: {},
      add_test: {},
      rem_test: {}
      },
    new_fail: 0,
    new_pass: 0,
    add_test: 0,
    rem_test: 0
  },
  files: {}
}


def analyse_test(test, r1, r2, filter)
  entry = nil

  filter["known_to_fail"] = filter["known_to_fail"] || {}
  filter["flacky_tests"] = filter["flacky_tests"] || {}
  filter["filter_out"] = {} unless filter["filter_out"]
  filter_report = filter["filter_out"][test]
  reason_filter = ""
  reason_filter += filter["filter_out"][test].to_s if filter["filter_out"]
  reason_filter += filter["comments"][test].to_s if filter["comments"]

  if(filter_report)
    changes_dict = @ret[:filtered_results][:changes]
    count_dict = @ret[:filtered_results]
  else
    changes_dict = @ret[:changes]
    count_dict = @ret[:results_delta]
  end

  if(r1 != nil)
    @ret[:baseline_results][:pass] += 1 if (PASSING_SENARIOS.include?(r1))
    @ret[:baseline_results][:fail] += 1 if (FAILING_SENARIOS.include?(r1))
    @ret[:baseline_results][:not_considered] += 1 if ((!PASSING_SENARIOS.include?(r1) && !FAILING_SENARIOS.include?(r1)))
    puts "#{test} = OTHER #{r1}" unless (PASSING_SENARIOS.include?(r1) || FAILING_SENARIOS.include?(r1))
  end
  if(r2 != nil)
    @ret[:results][:pass] += 1 if (PASSING_SENARIOS.include?(r2))
    @ret[:results][:fail] += 1 if (FAILING_SENARIOS.include?(r2))
    @ret[:baseline_results][:not_considered] += 1 if ((!PASSING_SENARIOS.include?(r2) && !FAILING_SENARIOS.include?(r2)))
    puts "#{test} = OTHER #{r1}" unless (PASSING_SENARIOS.include?(r2) || FAILING_SENARIOS.include?(r2))
  end

  if(r2 == nil && r1 != nil)
    puts "REM_TEST: #{test}    (#{r1} => (null))" if @enable_logging
    changes_dict[:rem_test][test] = { before: r1, after: "(null)", comments: reason_filter }
    count_dict[:rem_test] += 1
  elsif(r1 == nil && r2 != nil)
    puts "ADD_TEST: #{test}   ((null) => #{r2})" if @enable_logging
    changes_dict[:add_test][test] = { before: "(null)", after: r2, comments: reason_filter }
    count_dict[:add_test] += 1
  end

  if((r1 == 'FAIL' || r1 == 'UNRESOLVED' || r1 == nil) && r2 == 'PASS')
    puts "NEWLY_PASS: #{test}   (#{r1} => #{r2})" if @enable_logging
    changes_dict[:new_pass][test] = { before: r1 || "(null)", after: r2, comments: reason_filter }
    count_dict[:new_pass] += 1
  elsif((r1 == 'PASS' || r1 == nil) && (r2 == 'FAIL' || r2 == 'UNRESOLVED'))
    puts "NEWLY_FAIL: #{test}   (#{r1} => #{r2})" if @enable_logging
    changes_dict[:new_fail][test] = { before: r1 || "(null)", after: r2, comments: reason_filter }
    count_dict[:new_fail] += 1
  elsif(r1 == 'UNSUPPORTED' && r1 != r2)
    puts "ADD_TEST: #{test}   (#{r1} => #{r2})" if @enable_logging
    changes_dict[:add_test][test] = { before: r1, after: r2 || "(null)", comments: reason_filter }
    count_dict[:add_test] += 1
  elsif(r2 == 'UNSUPPORTED' && r1 != r2)
    puts "REM_TEST: #{test}   (#{r1} => #{r2})" if @enable_logging
    changes_dict[:rem_test][test] = { before: r1 || "(null)", after: r2, comments: reason_filter }
    count_dict[:rem_test] += 1
  end
end

def make_absolute_path(path)
  if File.absolute_path?(path)
    return path
  else
    return File.expand_path(path)
  end
end

def main1(options)

  


  file1_data = options[:files][0]
  file2_data = options[:files][1]

  file1 = File.join(file1_data[:file], options[:file])
  file2 = File.join(file2_data[:file], options[:file])

  file1 = make_absolute_path(file1)
  file2 = make_absolute_path(file2)
  

  @ret[:files][file1_data[:hash]] = read_results(file1)
  @ret[:files][file2_data[:hash]] = read_results(file2)

  data1 = File.exists?(file1) ? parse_sum(file1) : {}
  data2 = File.exists?(file2) ? parse_sum(file2) : {}

  tests1 = data1.keys.sort
  tests2 = data2.keys.sort

  tests_added = tests2 - tests1
  tests_removed = tests1 - tests2

  compare = !data1.empty? && !data2.empty?

  if compare
    (tests1 + tests2).uniq.each do |test|
      if tests_added.include?(test)
        analyse_test(test, nil, data2[test], @filters)
      elsif tests_removed.include?(test)
        analyse_test(test, data1[test], nil, @filters)
      else
        analyse_test(test, data1[test], data2[test], @filters)
      end
    end
  end


  @ret = { options[:target] => @ret }
end

def read_results(sum_file)
  
  return { 
	"PASS" => "ND",
	"FAIL" => "ND",
	"XPASS" => "ND",
	"XFAIL" => "ND",
	"UNRESOLVED" => "ND",
	"UNSUPPORTED" => "ND"
  } if !File.exists? sum_file


  mapping = {
    "expected passes" => "PASS",
    "unexpected failures" => "FAIL",
    "unexpected successes" => "XPASS",
    "expected failures" => "XFAIL",
    "unresolved testcases" => "UNRESOLVED",
    "unsupported tests" => "UNSUPPORTED"
  }

  ret = {}
  `tail -n 100 #{sum_file}`.split("\n").each do |l|
    if (l =~ /^# of/)
      l = l.split(/( |\t)/).select { |a| a != " " && a != "\t" && a != "" }
      name = l[2..-2].join(" ")
      num = l[-1].to_i

      ret[mapping[name]] = num
    end
  end
  return ret
end


def help()
  puts <<-EOF

Usage: ruby <script_name.rb> [options...]

Global options:
  --help                         Print usage and exit.

  -h  | --hash                   Specify path and hash. (<path>:<hash>)

  -f  | --file                   Specify file name to compare.

  -t  | --target                 Specify target name. (Otherwise "" is used)

  -v  | --verbose                 Enable verbose mode.

  -vv                            Specify verbose filter and enable verbose mode.
                                 ( npass | nfail | atest | rtest | passfail | failpass )

  -o  | --output                  Specify output mode.
                                 ( json | text | html )
  EOF
  exit()
end


def option_parser(argv)
  options = {}

  while argv.any?
    case argv.shift
    when "--help"
      help()
    when "--send-email"
      options[:send_email] = argv.shift
    when "-h", "--hash"
      opt = argv.shift.split(":")
      options[:files] ||= []
      options[:files] << { file: opt[0], hash: opt[1] }
    when "-o", "--output"
      options[:output] = argv.shift
    when "-f", "--file"
      options[:file] = argv.shift
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

  unless options[:files]
    abort("error: Files not found.")
  end

  return options
end


def generate_json(options)
  main1(options)
  str = JSON.pretty_generate(@ret)
  return str
end

def generate_text(options)
  main1(options)
  data = {}
  table = create_table(@ret, data, options, options[:filter])
  puts table
  if options[:verbose]
    str = print_compare(data)
  end
  return str
end
  
def generate_html(options)
  main1(options)
  data = {}
  compare_html = nil
  table = create_table(@ret, data, options, options[:filter])
  if options[:verbose]
    compare_html = generate_compare_html(data)
  end
  str = convert_table_html(table, compare_html)

  return str 
end


def main(argc, argv)
  if argc < 1
    help()
  end

  options = option_parser(argv)
  
  puts options

  output_format = options[:output] || "text"
  result = case output_format
           when "text"
             generate_text(options)
           when "json"
             generate_json(options)
           when "html"
             generate_html(options)
           else
             abort("error: Output format invalid")
           end

  

  puts(result)

  if options[:send_email]
    
    if options[:output] != "html"
      result = generate_html(options)
    end

    temp_file = `mktemp`.chomp
    File.write(temp_file, result)
    recipients = options[:send_email]

    script_path = File.join(__dir__, "lib", "my_email.py")
    system("python3 #{script_path} #{recipients} -f #{temp_file}")
    puts("python3 #{script_path} #{recipients} -f #{temp_file}")
  end
end

if __FILE__ == $PROGRAM_NAME
  main(ARGV.length, ARGV)
end

