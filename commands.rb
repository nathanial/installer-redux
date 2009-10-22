
module Commands
  def without_advice
    old_value = SETTINGS['global']['advise_commands']
    SETTINGS['global']['advise_commands'] = false
    yield 
    SETTINGS['global']['advise_commands'] = old_value
  end
end

class Command
  attr_accessor :name, :flags, :description

  def initialize(package, action)
    @package = package
    @preconditions = []
    @postconditions = []
    @before_advice = []
    @after_advice = []
    @action = action
  end

  def call(*args)
    result = nil
    advise = SETTINGS['global']['advise_commands']
    @preconditions.each do |cond|
      result = cond.call(@package, *args)
      return if result == :skip
      raise "PreCondition #{cond} failed" if result == :fail
    end
    @before_advice.each {|b| b.call(@package, *args)} if advise
    begin
      result = @action.call(*args) if @action
    rescue => e
      $stderr.puts "messed up #{@package.name} #@name because of #{e}"
      exit 1 unless SETTINGS['global']['debug']
      raise e
    end
    @after_advice.each {|b| b.call(@package, *args)} if advise

    @postconditions.each do |cond|
      result = cond.call(@package, *args)
      return if result == :skip
      raise "PostCondition #{cond} failed" if result == :fail
    end
    return result
  end
  
  def add_advice(position, advice)
    case position
    when :before 
      @before_advice << advice
    when :after
      @after_advice << advice
    else
      raise "Did not recognize position #{position} for advice"
    end
  end

  def add_precondition(condition)
    @preconditions << condition
  end
  
  def add_postcondition(condition)
    @postconditions << condition
  end
end

#condition results = one of [:skip, :continue, :fail]

def install_pre_condition
  lambda do |package, *args|
    return :skip if package.installed?
    return :continue
  end
end

def install_before_advice
  lambda do |package, *args|
    package.install_dependencies
    package.download_repositories
    package.create_directories
    package.download_other_stuff
    package.process_support_files
  end
end

def install_after_advice
  lambda do |package, *args|
    package.install_service
  end
end

def remove_pre_condition
  lambda do |package, *args|
    return :skip unless package.installed?
    return :continue
  end
end

def remove_before_advice
  lambda do |package, *args|
    package.remove_directories
  end
end

def default_install_command(package, &action)
  command = Command.new(package, action)
  command.add_advice(:before, install_before_advice)
  command.add_advice(:after, install_after_advice)
  command.add_precondition(install_pre_condition)
  return command
end

def default_remove_command(package, &action)
  command = Command.new(package, action)
  command.add_advice(:before, remove_before_advice)
  command.add_precondition(remove_pre_condition)
  return command
end

def default_installed_predicate(package, &action)
  command = Command.new package, lambda { |*args|
    return action.call(*args) if action
    return File.exists? package.project_directory 
  }
  return command
end

def default_reinstall_command(package, &action)
  command = Command.new package, lambda { |*args|
    return action.call(*args) if action
    package.remove
    package.install
  }
  return command
end
    
  
    
