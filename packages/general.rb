require 'package'

apt_package :ant
apt_package :ruby
apt_package :rubygems
apt_package :irb
apt_package :libopenssl_ruby, "libopenssl-ruby"
apt_package :mysql_server, "mysql-server"
apt_package :curl
apt_package :git, 'git-core'
apt_package :svn, 'subversion'
apt_package :ruby
apt_package :java
apt_package :python25, "python2.5"
apt_package :python26, "python2.6"
apt_package :matplotlib, "python-matplotlib"
apt_package :python_tz, "python-tz"
apt_package :emacs, "emacs-snapshot-gtk"
apt_package :apache2
apt_package :mod_python, "libapache2-mod-python"
apt_package :python_mysqldb, "python-mysqldb"
apt_package :expect
apt_package :python_serial, "python-serial"
apt_package :python_html5lib, "python-html5lib"
apt_package :python_imaging, "python-imaging"
apt_package :python_dev, "python-all-dev"
apt_package :sysvconfig

gem_package :http_client_gem, "httpclient"
gem_package :openssl_nonblock_gem, "openssl-nonblock"

package :python do
  predicate :installed? do
    some([:python25, :python26], lambda {|p| lookup(p).installed?})
  end
  command :install do
    lookup(:python25).install
  end
end
