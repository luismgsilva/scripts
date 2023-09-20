module Rules
  @@data = {}
  @@options = {}

  def to_json(&block)
    @@data[:json] = block
  end
  def to_text(&block)
    @@data[:text] = block
  end
  def to_chart(&block)
    @@data[:chart] = block
  end
  def to_html(&block)
    @@data[:html] = block
  end
  def set_default(name)
    @@options[:default] = name
  end
  def process_opts1(&block)
    @@data[:process_opts] = block
  end
  def Rules.included(mod)
    process_opts(ARGV)
  end
  def process_opts(args)
    @@options[:process_opts] = []
    while(args.include?("-h") or args.include?("-o"))
      opt = args.shift
      if (opt == '-o')
        @@options[:output] = args.shift.to_sym
      elsif (opt == '-h')
	      tmp = args.shift.split(":")
	      @@options[:files] = @@options[:files] || []
	      @@options[:files].push({ file: tmp[0], hash: tmp[1]  })
      else
        @@options[:process_opts].push(opt)
      end
    end
    @@options[:process_opts] += args
  end

  def execute()
    if @@options[:process_opts]
      @@data[:process_opts].call(@@options[:process_opts])
    end

    if(@@options[:output].nil?)
	    @@data[@@options[:default]].call(@@options[:files])
    else
    	@@data[@@options[:output]].call(@@options[:files])
    end
  end
end
