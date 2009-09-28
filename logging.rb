
$logging_callback = lambda {|t| puts t}

module Logging
  def log(text)
    $logging_callback.call(text)
  end
end
