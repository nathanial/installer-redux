
$packages = {}
$current_package = nil

def lookup(name)
  p = $packages[name]
  if not p
    raise "could not find package named #{name}"
  else 
    p
  end
end

def sh(text)
  raise "shell error with #{text}" unless system("#{text}")
end

def sh_f(text)
  system("#{text} > /dev/null")
end

def all(coll, pred)
  coll.each {|c| return false unless pred.call(c) }
  return true
end

def some(coll, pred)
  coll.each {|c| return true if pred.call(c) }
  return false
end

class Package
  attr_accessor :commands, :dependencies, :directories, :repository
  def initialize(name, settings)
    @project_directory = "/var/development/#{name}"
    @support = "/var/installer/support/#{name}"
    @settings = settings
    @commands = {}
    @dependencies = []
    @directories = []
    @repository = nil
  end

  def method_missing(sym, *args)
    case sym
    when :install
      install_dependencies
    end
    @commands[sym].call(*args)
  end

  private 

  def install_dependencies
    @dependencies.each do |d|
      lookup(d).install
    end
  end

  def creates_directories
    mkdir_p @project_directory
    @directories.each {|d| mkdir_p d}
  end

  def remove_directories
    rm_rf @project_directory
    @directories.each {|d| rm_rf d}
  end

  def process_support_files
    Dir.glob("#@support/*").each do |file|
      if File.file? file and /(\.*)(.erb$)/ =~ file
        fname = file.scan(/(\.*)(.erb$)/)[0][0]
        File.open(fname,"w") do |f|
          f.write(ERB.new(File.read(file)).result(get_binding))
        end
      end
    end
  end

  def depends_on(*args)
    puts "depends on #{args}"
    args.each {|a| @dependencies << a}
  end

  def creates_directories(*args)
    puts "directories #{args}"
    args.each {|a| @directories << a}
  end
  
  def has_repository(*args)
    puts "repository #{args}"
    @repository = args
  end

  def command(name, &block)
    puts "defining command #{name}"
    @commands[name] = block
  end
end

def package(name, &block)
  puts "defining #{name}"
  package = Package.new(name, {})
  package.instance_eval(&block)
  $packages[name] = package
end

def apt_package(*args)
end

def gem_package(*args)
end



