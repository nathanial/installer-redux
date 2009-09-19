require 'fileutils'
require 'package'
include FileUtils

package :pason_daemon do
  installs_service
  depends_on :python, :git, :tdsurface, :pywits
  repository :git, "git@github.com:teledrill/pason-daemon.git"
  
  command :install do
    ln_s "#{locate(:pywits).project_directory}/PyWITS", @project_directory
    ln_S "#{locate(:tdsurface).project_directory}", @project_directory
  end
end
