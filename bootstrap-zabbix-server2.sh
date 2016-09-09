#!/bin/sh

SOURCE="zabbix.devops.com"
VM=`cat /etc/hostname`

printf "\n>>>\n>>> WORKING ON: $VM ...\n>>>\n\n>>>\n>>> (STEP 1/4) Configuring system ...\n>>>\n\n\n"
sleep 5
echo 'root:devops' | chpasswd
timedatectl set-timezone Europe/Berlin
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service sshd restart
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
echo 0 > /sys/fs/selinux/enforce

printf "\n>>>\n>>> (STEP 2/4) Installing Pacemaker & Corosync ...\n>>>\n\n"
sleep 5
yum install -y pacemaker pcs
echo "hacluster:hacluster" | chpasswd
systemctl start pcsd
for SERVICE in pcsd corosync pacemaker; do systemctl enable $SERVICE; done

printf "\n>>>\n>>> (STEP 3/4) Installing Zabbix Server ...\n>>>\n\n"
sleep 5
yum install -y epel-release
yum update
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
yum install -y zabbix-server-mysql

printf "\n>>>\n>>> (STEP 4/4) Configuring Zabbix Server ...\n>>>\n\n"
sleep 5
cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.orig
cp /sources/$SOURCE/zabbix_server.conf /etc/zabbix/

printf "\n>>>\n>>> Finished bootstrapping $VM\n"
