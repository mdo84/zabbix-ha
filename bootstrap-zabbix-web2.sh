#!/bin/sh

SOURCE="zabbix.devops.com"
VM=`cat /etc/hostname`

printf "\n>>>\n>>> WORKING ON: $VM ...\n>>>\n\n"
echo 'root:devops' | chpasswd
timedatectl set-timezone Europe/Berlin
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service sshd restart

printf "\n>>>\n>>> (STEP 1/4) Disabling SELinux ...\n>>>\n\n"
sleep 5
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
echo 0 > /sys/fs/selinux/enforce

printf "\n>>>\n>>> (STEP 2/4) Installing Zabbix Web ...\n>>>\n\n"
sleep 5
yum install -y epel-release
yum update
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
yum install -y httpd php zabbix-web-mysql

printf "\n>>>\n>>> (STEP 4/4) Configuring Zabbix Web ...\n>>>\n\n"
sleep 5
cp /etc/php.ini /etc/php.ini.orig
sed -i -e 's/max_execution_time = 30/max_execution_time = 600/' \
-e 's/max_input_time = 60/max_input_time = 600/' \
-e 's/memory_limit = 128M/memory_limit = 256M/' \
-e 's/post_max_size = 8M/post_max_size = 32M/' \
-e 's/upload_max_filesize = 2M/upload_max_filesize = 16M/' \
-e 's/;date.timezone =/date.timezone = Europe\/Berlin/' /etc/php.ini
cp /sources/$SOURCE/zabbix.conf.php /etc/zabbix/web/
systemctl start httpd
systemctl enable httpd

printf "\n>>>\n>>> Finished bootstrapping $VM\n"
