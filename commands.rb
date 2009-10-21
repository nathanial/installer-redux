class Command
  attr_accessor :name, :flags, :description

  def initialize(package, &action)
    @package = package
    @preconditions = []
    @postconditions = []
    @before_advice = []
    @after_advice = []
    @action = action
  end

  def call(*args)
    @before_advice.each {|b| b.call(@package, *args)}
    @action.call(*args) if @action
    @after_advice.each {|b| b.call(@package, *args)}
  end
  
  def add_advice(position, &block)
    case position
    when :before 
      @before_advice << block
    when :after
      @after_advice << block
    else
      raise "Did not recognize position #{position} for advice"
    end
  end

  def add_precondition(&condition)
    @preconditions << condition
  end
  
  def add_postcondition(&condition)
    @postconditions << condition
  end
end

#condition results = one of [:skip, :continue, :fail]

class InstallPreCondition
  def call(package, *args)
    return :skip if package.installed?
    return :continue
  end
end

class InstallBeforeAdvice 
  def call(package, *args)
    return if package.installed?
    package.install_dependencies
    package.download_repositories
    package.create_directories
    package.download_other_stuff
    package.process_support_files
  end
end

class InstallAfterAdvice
  def call(package, *args)
    package.install_service
  end
end

class RemovePreCondition
  def call(package, *args)
    return :skip if not package.installed?
    return :continue
  end
end

class RemoveBeforeAdvice
  def call(package, *args)
    package.remove_directories
  end
end

def default_install_command(package, &action)
  command = Command.new(package, &action)
  command.add_advice(:before, InstallBeforeAdvice.new)
  command.add_advice(:after, InstallAfterAdvice.new)
  command.add_precondition(InstallPreCondition.new)
  return command
end

def default_remove_command(package, &action)
  command = Command.new(package, &action)
  command.add_advice(:before, RemoveBeforeAdvice.new)
  command.add_precondition(RemovePreCondition.new)
  return command
end

def default_installed_predicate(package, &action)
  command = Command.new do |*args|
    return File.exists? package.project_directory if not action
    return action.call(*args)
  end
  return command
end

def default_reinstall_command(package, &action)
  command = Command.new do |*args|
    if action
      return action.call(*args)
    else
      package.remove
      package.install
    end
  end
  return command
end
    
  
    
