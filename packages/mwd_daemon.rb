require 'fileutils'
require 'package'
include FileUtils

package :mwd_daemon do
  installs_service
  depends_on :python, :git, :tdsurface
  repository :git, "git@github.com:teledrill/mwd-daemon.git"
  description """
mwd_daemon pulls data from Kenneth's Labview Application into the database via 
tdsurface django orm
"""
  
  command :install do
    ln_s lookup(:tdsurface).project_directory, @project_directory
  end
end


