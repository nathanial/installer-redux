class Command
  attr_accessor :name, :flags, :description

  def initialize(&block)
    @block = block
  end

  def call(*args)
    @block.call(*args)
  end
end
