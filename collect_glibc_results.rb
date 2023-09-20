
def collector(workspace_dir)
  file = ""
  `find #{workspace_dir} -name "*.test-result"`.split().each do |path|
    first_line = File.open(path).first
    file += first_line if first_line =~ /[A-Z0-9]+:\s/
  end
  return file
end

def header()
  str=<<EOF
Test run by #{`echo $USER`} on #{`date`}

		=== glibc tests ===


EOF

  return str
end

def summary(file)
  str=<<EOF

                === glibc Summary ===
# of expected passes            #{file.scan(/^PASS+/).size}
# of unexpected failures        #{file.scan(/^FAIL+/).size}
# of unexpected successes       #{file.scan(/^XPASS+/).size}
# of expected failures          #{file.scan(/^XFAIL+/).size}
# of unresolved testcases       #{file.scan(/^UNRESOLVED+/).size}
# of unsupported tests          #{file.scan(/^UNSUPPORTED+/).size}
EOF
  return str
end

def main(argc, argv)

  directory_path = argv[0]
  if argc != 1
    abort("Usage: ruby script_name.rb <workspace_path>")
  end
  if !File.directory?(directory_path)
    abort("#{directory_path} does not exist as a directory")
  end

  file = ""
  file = file + header()
  file = file + collector(directory_path)
  file = file + summary(file)
  puts file
end

if __FILE__ == $PROGRAM_NAME
  main(ARGV.length, ARGV)
end
