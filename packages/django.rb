require 'fileutils'
include FileUtils

python_site_packages = `python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()"`.chomp

package :django do
  depends_on :python, :svn
  repository :svn, "http://code.djangoproject.com/svn/django/trunk/"
  description """
django svn package; primarily used for tdsurface;
"""
  
  c_description "installs django into site packages and copies django-admin into /usr/local/bin"
  command :install do 
    mv "#@project_directory/django", "#{python_site_packages}/django", :force => true
    ln_sf "#{python_site_packages}/django/bin/django-admin.py", "/usr/local/bin"
  end

  c_description "removes django from site packages and django-admin from /usr/local/bin"
  command :remove do
    rm_rf "#{python_site_packages}/django"
    rm_rf '/usr/local/bin/django-admin.py'
  end
  
  predicate :installed? do
    File.exists? "#{python_site_packages}/django"
  end
end
