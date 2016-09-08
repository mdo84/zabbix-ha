#!/bin/sh

SOURCE="mariadb.devops.com"
VM=`cat /etc/hostname`

printf "\n>>>\n>>> WORKING ON: $VM ...\n>>>\n\n"
echo 'root:devops' | chpasswd
timedatectl set-timezone Europe/Berlin
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service sshd restart

printf "\n>>>\n>>> (STEP 1/3) Disabling SELinux ...\n>>>\n\n"
sleep 5
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
echo 0 > /sys/fs/selinux/enforce

printf "\n>>>\n>>> (STEP 2/3) Installing MariaDB ...\n>>>\n\n"
sleep 5
yum update
yum install -y mariadb-server mariadb
cp /sources/$SOURCE/slave.cnf /etc/my.cnf.d/
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation <<EOF

y
devops
devops
y
y
y
y
EOF

printf "\n>>>\n>>> (STEP 3/3) Configuring MariaDB ...\n>>>\n\n"
sleep 5
mysql -uroot -pdevops -e 'CREATE DATABASE zabbix;'
mysql -uroot -pdevops zabbix < /sources/$SOURCE/create.sql
mysql -uroot -pdevops -e 'STOP SLAVE;'
ML_FILE=`grep mariadb /sources/$SOURCE/master_status | awk '{print $1}'`
ML_LOG=`grep mariadb /sources/$SOURCE/master_status | awk '{print $2}'`
mysql -uroot -pdevops -e "CHANGE MASTER TO MASTER_HOST='mariadb-master.devops.com', MASTER_USER='zabbix', MASTER_PASSWORD='zabbix', MASTER_LOG_FILE='$ML_FILE', MASTER_LOG_POS=$ML_LOG;"
mysql -uroot -pdevops -e 'SLAVE START;'
sleep 2 && mysql -uroot -pdevops -e 'SHOW SLAVE STATUS\G;' | grep "Running"
rm -f /sources/$SOURCE/master_status

printf "\n>>>\n>>> Finished bootstrapping $VM\n>>>\n\n>>> MariaDB is reachable via:\n>>> USERNAME: root\n>>> PASSWORD: devops\n"
