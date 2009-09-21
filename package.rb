#!/usr/bin/ruby
require 'rubygems'
require 'fileutils'
require 'httpclient'
require 'erb'

$packages = {}

def lookup(name)  
  p = $packages[name]
  if not p
    raise "could not find package named #{name} out of #{$packages}"
  else 
    p
  end
end

def sh(text)
  puts text
  raise "shell error with #{text}" unless system(text)
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
  attr_accessor :package_commands, :package_dependencies
  attr_accessor :package_directories, :package_repository
  attr_accessor :package_downloads, :project_directory

  def initialize(name, settings)
    @name = name
    @project_directory = "/var/development/#{name}"
    @support = "/home/nathan/Projects/installer-redux/support/#{name}"
    @settings = settings
    @package_commands = {}
    @package_dependencies = []
    @package_directories = []
    @package_repository = []
    @package_downloads = []
    @package_installs_service = false
    @install_script = "#@support/#{name}"
  end

  def method_missing(sym, *args)
    case sym
    when :install
      return if installed?
      install_dependencies
      download_repositories
      create_directories
      download_other_stuff
      process_support_files
      install_service
    when :remove
      return if not installed?
      remove_directories
      return if not @package_commands[sym]
    when :installed?
      if not @package_commands[sym]
        return File.exists?(@project_directory)
      end
    end
    puts "calling #{sym} on #{self}"
    command = @package_commands[sym]
    if command
      command.call(*args)
    else 
      super.method_missing(sym, *args)
    end
  end

  def get_binding 
    binding
  end

  private 

  def installs_service
    @package_installs_service = true
  end

  def install_service
    return unless @package_installs_service
    script_name = (@install_script.split /\//).last
    cp @install_script, "/etc/init.d/"
    sh("chmod a+xr /etc/init.d/#{script_name}")
    sh("update-rc.d #{script_name} defaults")
    sh("service #{script_name} start")
  end

  def install_dependencies
    @package_dependencies.each do |d|
      lookup(d).install
    end
  end

  def create_directories
    mkdir_p @project_directory
    @package_directories.each {|d| mkdir_p d}
  end

  def download_repositories
    client = HTTPClient.new
    case @package_repository[0]
    when :git 
      sh("git clone #{package_repository[1]} #@project_directory")
    when :svn 
      sh("svn checkout #{package_repository[1]} #@project_directory")
    end
  end

  def download_other_stuff
    client = HTTPClient.new 
    @package_downloads.each do |pd|
      url = pd[:url]
      file = pd[:extract]
      dest = pd[:to]
      puts "downloading package #{file}"
      open("#@project_directory/#{file}", "w") do |f|
        f.write(client.get_content(url))
      end
      sh("cd #@project_directory && tar xf #{file}")
      sh("mv #@project_directory/#{file.chomp('.tar.gz')}/* #{dest}")
    end
  end

  def remove_directories
    rm_rf @project_directory
    @package_directories.each {|d| rm_rf d}
  end

  def process_support_files
    Dir.glob("#@support/*").each do |file|
      if File.file? file and /(\.*)(.erb$)/ =~ file
        fname = file.scan(/(.*)(.erb$)/)[0][0]
        File.open(fname,"w") do |f|
          f.write(ERB.new(File.read(file)).result(get_binding))
        end
      end
    end
  end

  def depends_on(*args)
    args.each {|a| @package_dependencies << a}
  end

  def directories(*args)
    args.each {|a| @package_directories << a}
  end
  
  def repository(*args)
    @package_repository = args
  end

  def command(name, &block)
    @package_commands[name] = block
  end

  def predicate(name, &block)
    @package_commands[name] = block
  end
  
  def downloads(options)
    @package_downloads << options
  end

end

def package(name, &block)
  package = Package.new(name, GLOBAL_SETTINGS)
  package.instance_eval(&block)
  $packages[name] = package
end

$installed_deb_packages = `dpkg --list`

def apt_package(*args)
  name = args.shift
  apt_name = name
  if not args.empty?
    apt_name = args.shift
  end

  package name do
    command :install do
      sh("aptitude -y install #{apt_name}")
    end
    command :remove do 
      sh("aptitude -y remove #{aptitude}")
    end
    predicate :installed? do
      puts "checking if #{name} is installed"
      installed = $installed_deb_packages.reject {|r| not r =~ /^ii/ or not r =~ / #{apt_name} /}
      not installed.empty?
    end
  end
end

def gem_package(*args)
  name = args.shift
  if not args.empty?
    gem_name = args.shift
  end
  package name do
    command :install do
      sh("gem install #{gem_name}")
    end
    command :remove do
      sh("gem remove #{gem_name}")
    end
    predicate :installed? do
      false
    end
  end
end

def py_package(name, options)
  package name do
    depends_on :python
    depends_on(*options[:dependencies])
    downloads :url => options[:url], :extract => options[:tarball], :to => @project_directory
    command :install do
      sh("cd #@project_directory && python setup.py install")
    end
  end
end
    
    
