#!/bin/sh

SOURCE="zabbix.devops.com"
VM=`cat /etc/hostname`

printf "\n>>>\n>>> WORKING ON: $VM ...\n>>>\n\n"
echo 'root:devops' | chpasswd
timedatectl set-timezone Europe/Berlin
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service sshd restart

printf "\n>>>\n>>> (STEP 1/5) Disabling SELinux ...\n>>>\n\n"
sleep 5
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
echo 0 > /sys/fs/selinux/enforce

printf "\n>>>\n>>> (STEP 2/5) Installing Pacemaker & Corosync ...\n>>>\n\n"
sleep 5
yum install -y pacemaker pcs
echo "hacluster:hacluster" | chpasswd
systemctl start pcsd
systemctl enable pcsd
systemctl enable corosync
systemctl enable pacemaker

printf "\n>>>\n>>> (STEP 3/5) Installing Zabbix Server ...\n>>>\n\n"
sleep 5
yum install -y epel-release
yum update
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
yum install -y zabbix-server-mysql

printf "\n>>>\n>>> (STEP 4/5) Configuring Zabbix Server ...\n>>>\n\n"
sleep 5
cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.orig
sed -i -e 's/# DBHost=localhost/DBHost=mariadb-master.devops.com/' \
-e 's/# DBPassword=/DBPassword=zabbix/' \
-e 's/# SourceIP=/SourceIP=192.168.10.15/' \
-e 's/# ListenIP=127.0.0.1/ListenIP=192.168.10.15/' /etc/zabbix/zabbix_server.conf

printf "\n>>>\n>>> (STEP 5/5) Configuring Zabbix cluster functionality ...\n>>>\n\n"
sleep 5
pcs cluster auth zabbix-server1.devops.com zabbix-server2.devops.com <<EOF
hacluster
hacluster
EOF
pcs cluster setup --name zabbix-server zabbix-server1.devops.com zabbix-server2.devops.com
pcs cluster start --all
pcs status cluster
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
pcs resource create cluster_vip ocf:heartbeat:IPaddr2 ip=192.168.10.15 cidr_netmask=24 nic=eth1 op monitor interval=20s
pcs resource create zabbix_server systemd:zabbix-server op monitor interval=10s
pcs constraint colocation add zabbix_server cluster_vip
pcs constraint order cluster_vip then zabbix_server
pcs resource restart zabbix_server
pcs status

printf "\n>>>\n>>> Finished bootstrapping $VM\n>>>\n\n>>> zabbix-server VIP is reachable via:\n>>> 192.168.10.15\n"
