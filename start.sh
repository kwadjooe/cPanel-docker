#!/bin/bash

export LC_ALL="en_US.utf8"
iptables --flush
/scripts/restartsrv_cpsrvd
systemctl restart mysql

echo "[client]" > /root/.my.cnf;
echo "password=" >> /root/.my.cnf;
echo "user=root" >> /root/.my.cnf;

mysql_password=$(</dev/urandom tr -dc '12345!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c8; echo "");

mysql << EOF
use mysql;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$mysql_password');
EOF

echo "[client]" > /root/.my.cnf;
echo "password=$mysql_password" >> /root/.my.cnf;
echo "user=root" >> /root/.my.cnf;

cp /root/.my.cnf /root/.$mysql_password.pass;

/scripts/mysqlconnectioncheck

rm -rf /var/cpanel/cpnat
new_ip=$(ifconfig | grep 'inet'| grep -v '127.0.0.1'| cut -d: -f2 | awk '{ print $2}' |grep -v "10." |grep -v '^\s*$');
#echo $new_ip > /var/cpanel/cpnat;
grep -q ADDR /etc/wwwacct.conf && sed -i_bak "s/\(ADDR\) .*/\1 $new_ip/" /etc/wwwacct.conf || echo "ADDR $new_ip" >> /etc/wwwacct.conf

/scripts/mainipcheck

/scripts/rebuildhttpdconf

/scripts/restartsrv_httpd

/bin/bash
