require 'package'
require 'commands'
require 'packages/general'
include FileUtils

package :admin_packages do
  depends_on :geany, :mysql_admin

  command :installed? do 
   all([:geany, :mysql_admin], lambda {|p| lookup(p).installed?})
  end
end
