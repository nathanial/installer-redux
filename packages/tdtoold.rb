require 'fileutils'
include FileUtils
include Logging

package :tdtoold do
  depends_on :python, :git, :python_serial
  repository :git, "git@github.com:teledrill/tdtoold.git"

  command :install do
    sh("cd #@project_directory && python setup.py install --install-scripts=/usr/local/bin")
    touch "/var/log/tdtoold.log"
    sh("chmod a+rw /var/log/tdtoold.log")
    sh("update-rc.d tdtoold defaults")
  end

  command :refresh do
    sh("cd #@project_directory && python setup.py install --install-scripts=/usr/local/bin")
    touch "/var/log/tdtoold.log"
    sh("chmod a+rw /var/log/tdtoold.log")
    sh("update-rc.d tdtoold defaults")
  end

  command :remove do 
    sh("update-rc.d -f tdtoold remove")
  end
end

    
