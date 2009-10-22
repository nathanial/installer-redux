require 'rubygems'
require 'httpclient'
require 'fileutils'
include FileUtils

report_lab_url = "http://www.reportlab.org/ftp/ReportLab_2_3.tar.gz"
package :report_lab do 
  depends_on :python, :python_dev
  downloads(:url => report_lab_url,
            :extract => 'ReportLab_2_3.tar.gz',
            :to => @project_directory)

  command :install do
    sh("cd #@project_directory && python setup.py install")
  end
end
  
    
