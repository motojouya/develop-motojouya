#!/bin/bash
set -x

region=$1
ssh_port=$2
volume_id=$3
device_name=$4
username=$5
domain=$6
hosted_zone_id=$7
# userid=$8

export AWS_DEFAULT_REGION=$region
cd /home/ubuntu
ip=$(ec2-metadata -v | awk '{print $2}')
# instance_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)

# apt
apt-get update
# apt-get install -y nvme-cli
apt-get install -y jq tmux tree xauth git silversearcher-ag sqlite3 curl ca-certificates gnupg software-properties-common nginx

# aws cli
# TODO install!

# mount ebs volume
# aws ec2 attach-volume --volume-id vol-$volume_id --instance-id $instance_id --device /dev/xvdb --region $region
# aws ec2 wait volume-in-use --volume-ids vol-$volume_id
# device=$(nvme list | grep $volume_id | awk '{print $1}' | xargs)
# while [ -z $device ]; do
#     sleep 1
#     device=$(nvme list | grep $volume_id | awk '{print $1}' | xargs)
# done
# until [ -e $device ]; do
#     sleep 1
# done
mkdir /home/$username
# mkfs -t xfs $device
mount $device_name /home/$username

# add user
# adduser $username
# useradd -u $userid -d /home/$username -s /bin/bash $username
useradd -d /home/$username -s /bin/bash $username
gpasswd -a $username sudo
cp -arpf /home/ubuntu/.ssh/authorized_keys /home/$username/.ssh/authorized_keys
chown $username /home/$username
chgrp $username /home/$username
chown -R $username /home/$username/.ssh
chgrp -R $username /home/$username/.ssh

# sshd
curl https://raw.githubusercontent.com/motojouya/develop-motojouya/main/resources/sshd_config.tmpl -O
cp sshd_config.tmpl /etc/ssh/sshd_config
systemctl restart ssh

# ssh port
curl https://raw.githubusercontent.com/motojouya/develop-motojouya/main/resources/ssh.socket.tmpl -O
sed -e s/{%port%}/$ssh_port/g ssh.socket.tmpl > ssh.socket.init
cp ssh.socket.init /lib/systemd/system/ssh.socket
systemctl restart ssh.socket
systemctl daemon-reload
# again but mystery
# systemctl restart ssh.socket
# systemctl daemon-reload

# # let's encrypt
# cd /etc
# cp /home/$username/letsencrypt.tar.gz letsencrypt.tar.gz
# tar -xzf letsencrypt.tar.gz
# cd /home/ubuntu

# nginx
curl https://raw.githubusercontent.com/motojouya/develop-motojouya/main/resources/http.conf.tmpl -O
sed -e s/{%domain%}/$domain/g http.conf.tmpl > http.conf.init
cp http.conf.init /etc/nginx/conf.d/http.conf
systemctl start nginx.service

# register route53
curl https://raw.githubusercontent.com/motojouya/develop-motojouya/main/resources/dyndns.tmpl -O
sed -e "s/{%IP%}/$ip/g;s/{%domain%}/$domain/g" dyndns.tmpl > change_resource_record_sets.json
aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch file:///home/ubuntu/change_resource_record_sets.json

# node
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs
npm install -g npx typescript typescript-language-server

# docker
mkdir -m 0755 -d /etc/apt/keyrings # install?
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

gpasswd -a $username docker
systemctl restart docker

# terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
apt update
apt-get install terraform

# certbot
# pip
# curl -O https://bootstrap.pypa.io/get-pip.py
# python3 get-pip.py
# dnf install -y python3 augeas-libs pip
# python3 -m venv /opt/certbot/
# /opt/certbot/bin/pip install --upgrade pip
# /opt/certbot/bin/pip install certbot
# ln -s /opt/certbot/bin/certbot /usr/bin/certbot
# add-apt-repository -y universe
# add-apt-repository -y ppa:certbot/certbot
# apt update
# apt install -y certbot python-certbot-nginx

# # others
# /home/$username/.fzf/install --bin
