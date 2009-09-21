spawn python "/var/development//tdsurface/manage.py" "syncdb"

set timeout -1

expect "(yes/no)*:" { send "yes\n" }
expect "Username*:" { send "teledrill\n" }
expect "E-mail*:" { send "nathan@erdosmiller.com\n" }
expect "Password*:" { send "scimitar1\n" }
expect "Password*:" { send "scimitar1\n" }
expect eof {exit 0}

