require 'package'
require 'fileutils'
include FileUtils

pisa_url = "http://pypi.python.org/packages/source/p/pisa/pisa-3.0.32.tar.gz#md5=d68f2f76e04b10f73c07ef4df937b243"

py_package(:pisa, 
           :url => pisa_url, 
           :tarball => 'pisa-3.0.32.tar.gz',
           :dependencies => [:pypdf])

py_package(:pypdf,
           :url => "http://pybrary.net/pyPdf/pyPdf-1.12.tar.gz",
           :tarball => 'pyPdf-1.12.tar.gz',
           :dependencies => [])


