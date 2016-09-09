#!/bin/sh

SOURCE="zabbix.devops.com"
VM=`cat /etc/hostname`

printf "\n>>>\n>>> WORKING ON: $VM ...\n>>>\n\n>>>\n>>> (STEP 1/3) Configuring system ...\n>>>\n\n\n"
sleep 5
echo 'root:devops' | chpasswd
timedatectl set-timezone Europe/Berlin
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service sshd restart
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
echo 0 > /sys/fs/selinux/enforce

printf "\n>>>\n>>> (STEP 2/3) Installing Zabbix Web ...\n>>>\n\n"
sleep 5
yum install -y epel-release
yum update
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
yum install -y httpd php zabbix-web-mysql

printf "\n>>>\n>>> (STEP 3/3) Configuring Zabbix Web ...\n>>>\n\n"
sleep 5
cp /etc/php.ini /etc/php.ini.orig
cp /sources/$SOURCE/php.ini /etc/
cp /sources/$SOURCE/zabbix.conf.php /etc/zabbix/web/
systemctl start httpd && systemctl enable httpd

printf "\n>>>\n>>> Finished bootstrapping $VM\n"
