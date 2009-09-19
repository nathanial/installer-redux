require 'package'
require 'fileutils'
include FileUtils

tarball = "http://softlayer.dl.sourceforge.net/project/cheetahtemplate/Cheetah/v2.2.1/Cheetah-2.2.1.tar.gz"

package :cheetah do 
  depends_on :python
  downloads :tarball => tarball, :unpack_to => @project_directory

  command :install do
    sh("cd #@project_directory && python setup.py install")
  end
end
