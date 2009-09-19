require 'package'
require 'fileutils'
include FileUtils

pisa_url = "http://pypi.python.org/packages/source/p/pisa/pisa-3.0.32.tar.gz#md5=d68f2f76e04b10f73c07ef4df937b243"

package :pisa do
  depends_on :python
  downloads :tarball => pisa_url, :explodes_to => @project_directory
  
  command :install do 
    sh("cd #@project_directory && python setup.py install")
  end
end
    
  
