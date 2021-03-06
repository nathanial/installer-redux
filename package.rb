#!/usr/bin/ruby
require 'logging'
require 'commands'
require 'rubygems'
require 'fileutils'
require 'httpclient'
require 'erb'
include Logging

$packages = {}

def lookup(name)  
  p = $packages[name]
  if not p
    $stderr.puts "could not find package named #{name}"
    exit 1
  else 
    p
  end
end

def sh(text)
  log text
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
  attr_accessor :name
  attr_accessor :package_commands, :package_dependencies
  attr_accessor :package_directories, :package_repository
  attr_accessor :package_downloads, :project_directory
  attr_accessor :package_description

  def initialize(name, settings)
    @name = name
    @flags = []
    @c_flags = []
    @c_descriptions = []
    @project_directory = "#{settings['global']['directory']}/#{name}"
    @support = "support/#{name}"
    @settings = settings
    @package_commands = {}
    @package_dependencies = []
    @package_directories = []
    @package_repository = []
    @package_downloads = []
    @package_installs_service = false
    @install_script = "#@support/#{name}"
    @package_description = "None"
    create_default_methods
  end

  def create_default_methods
    command :install
    command :remove
    command :reinstall
    command :installed?
  end

  def to_s
    @name.to_s
  end

  def inspect
    @name.to_s
  end

  def invoke_if_exists(sym, *args)
    if @package_commands[sym]
      @package_commands[sym].call(*args)
    else
      raise "could not find command #{sym}"
    end
  end

  def get_binding 
    binding
  end

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
    return if (@flags.include? :apt_package or
               @flags.include? :gem_package)
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
      log "downloading package #{file}"
      open("#@project_directory/#{file}", "w") do |f|
        f.write(client.get_content(url))
      end
      sh("cd #@project_directory && tar xf #{file}")
      sh("mv #@project_directory/#{file.chomp('.tar.gz')}/* #{dest}")
    end
  end

  def remove_directories
    log "removing directories for #@name"
    log "rm -rf #@project_directory"
    rm_rf @project_directory
    @package_directories.each do |d|
      log "rm -rf #{d}"
      rm_rf d
    end
  end

  def process_support_files
    log "processing directory #@support/*"
    Dir.glob("#@support/*").each do |file|
      log "processing #{file}"
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

  def description(desc)
    @package_description = desc
  end

  def command(name, &block)
    raise "name cannot be null : #{name}" unless name
    c = nil
    case name
    when :install
      c = default_install_command(self, &block)
    when :remove
      c = default_remove_command(self, &block)
    when :installed? 
      c = default_installed_predicate(self, &block)
    when :reinstall
      c = default_reinstall_command(self, &block)
    else
      c = Command.new(self, block)
    end
    c.name = name
    @package_commands[name] = c
    (class << self; self; end).class_eval do
      define_method name do |*args| 
        @package_commands[name].call(*args)
      end
    end
  end

  def downloads(options)
    @package_downloads << options
  end

end

def package(name, &block)
  package = Package.new(name, SETTINGS)
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
    @flags << :apt_package
    command :install do
      sh("aptitude -y install #{apt_name}")
    end
    command :remove do 
      sh("aptitude -y remove #{apt_name}")
    end
    command :installed? do
      log "checking if #{name} is installed"
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
    @flags << :gem_package
    command :install do
      sh("gem install #{gem_name}")
    end
    command :remove do
      sh("gem remove #{gem_name}")
    end
    command :installed? do
      false
    end
  end
end

def py_package(name, options)
  package name do
    @flags << :py_package
    depends_on :python
    depends_on(*options[:dependencies])
    downloads :url => options[:url], :extract => options[:tarball], :to => @project_directory
    command :install do
      sh("cd #@project_directory && python setup.py install")
    end
  end
end
    
    
