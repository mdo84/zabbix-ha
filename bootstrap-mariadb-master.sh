#!/bin/sh

SOURCE="mariadb.devops.com"
VM=`cat /etc/hostname`

printf "\n>>>\n>>> WORKING ON: $VM ...\n>>>\n\n>>>\n>>> (STEP 1/3) Configuring system ...\n>>>\n\n\n"
sleep 5
echo 'root:devops' | chpasswd
timedatectl set-timezone Europe/Berlin
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service sshd restart
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
echo 0 > /sys/fs/selinux/enforce

printf "\n>>>\n>>> (STEP 2/3) Installing MariaDB ...\n>>>\n\n"
sleep 5
yum update
yum install -y mariadb-server mariadb
cp /sources/$SOURCE/master.cnf /etc/my.cnf.d/
systemctl start mariadb && systemctl enable mariadb
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
mysql -uroot -pdevops -e 'CREATE DATABASE zabbix;' \
-e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%' IDENTIFIED BY 'zabbix';" \
-e 'FLUSH PRIVILEGES;'
mysql -uroot -pdevops zabbix < /sources/$SOURCE/create.sql
mysql -uroot -pdevops -e 'STOP SLAVE;' \
-e "GRANT REPLICATION SLAVE ON *.* TO 'zabbix'@'%' IDENTIFIED BY 'zabbix';" \
-e 'FLUSH PRIVILEGES;' \
-e 'FLUSH TABLES WITH READ LOCK;'
mysql -uroot -pdevops -e 'SHOW MASTER STATUS\g' > /sources/$SOURCE/master_status

printf "\n>>>\n>>> Finished bootstrapping $VM\n>>>\n\n>>> MariaDB is reachable via:\n>>> USERNAME: root\n>>> PASSWORD: devops\n"
