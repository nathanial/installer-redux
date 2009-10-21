require 'package'
require 'packages/general'
require 'fileutils' 
include FileUtils

package :tdsurface do
  description """
the most important package of them all; webapp the does it all;
controls tool, gathers pason and mwd data...
"""
  depends_on :mysql_server, :apache2, :svn, :git, :django, :expect
  depends_on :python_tz, :matplotlib, :mod_python, :python_mysqldb
  depends_on :pisa, :report_lab, :python_html5lib, :pypdf, :python_imaging
  depends_on :cheetah

  directories '/var/matplotlib', '/var/log/tdsurface'
  repository :git, "git@github.com:teledrill/tdsurface.git"

  python_site_packages = `python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()"`.chomp
  password = @settings[:tdsurface][:password]
  
  command :install do
    install_project_files
    sh("usermod -a -G dialout www-data")
    create_database 
    restart_apache
  end
  
  command :remove do
    sh_f("service apache2 stop")
    rm_rf '/var/www/media'
    rm_f '/etc/apache2/conf.d/tdsurface'
    sh_f("service apache2 start")
  end

  command :restart_apache do
    sh("service apache2 restart")
  end

  command :install_project_files do
    cp "#@support/django_local_settings.py", "#@project_directory/settings_local.py"
    chown("root", "www-data", ["/var/log/tdsurface"])
    cp_r "#{python_site_packages}/django/contrib/admin/media", "/var/www/media"
    cp_r "#@project_directory/media", "/var/www/"
    cp "#@support/tdsurface_apache.conf", '/etc/apache2/conf.d/tdsurface'
    chmod_R(0777, ["/var/matplotlib", "/var/log/tdsurface"])
    sh("touch /var/log/tdsurface/tdsurface.log")
    sh("chmod a+rw /var/log/tdsurface/tdsurface.log")
  end
  
  command :remove_database do
    system("""
    mysql --user=root --password=#{password} -e \"
       DROP DATABASE tdsurface;
       DROP USER 'tdsurface'@'localhost';\"
""")
  end
  
  command :create_database do
    begin
      sh("""mysql --user=root --password=#{password} -e \"
CREATE DATABASE tdsurface;
CREATE USER 'tdsurface'@'localhost' IDENTIFIED BY '#{password}';
GRANT ALL PRIVILEGES ON *.* TO 'tdsurface'@'localhost';\"
""")
      sh("expect #@support/expect_script.tcl")
    rescue
      warn "could not create database or database already exists"
    end
  end

  command :reinstall_database do
    remove_database
    create_database
  end

  command :redeploy_from do |directory|
    remove
    install
    sh("cd #@project_directory && DJANGO_SETTINGS_MODULE=\"settings\" python -c 'from django.contrib.sessions.models import Session; Session.objects.all().delete()'")
  end
end    
