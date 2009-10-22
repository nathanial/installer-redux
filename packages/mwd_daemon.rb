require 'fileutils'
require 'package'
include FileUtils

package :mwd_daemon do
  installs_service
  depends_on :python, :git, :tdsurface
  repository :git, "git@github.com:teledrill/mwd-daemon.git"
  
  command :install do
    ln_s lookup(:tdsurface).project_directory, @project_directory
  end
end


