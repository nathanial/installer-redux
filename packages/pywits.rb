require 'package'

package :pywits do
  depends_on :python, :git
  repository :git, "git@github.com:erdosmiller/PyWITS.git"
  description """
library for communicating over wits0 protocol
"""
end
