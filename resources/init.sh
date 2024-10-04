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
# password=$9

export AWS_DEFAULT_REGION=$region
cd /home/ec2-user
ip=$(ec2-metadata -v | awk '{print $2}')
# instance_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)

# install commands
yum update -y
# yum install -y nvme-cli
yum install -y jq
yum install -y tmux
yum install -y tree
yum install -y xauth
yum install -y silversearcher-ag

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
adduser $username
# useradd -u $userid -d /home/$username -s /bin/bash $username
# gpasswd -a $username sudo
cp -arpf /home/ec2-user/.ssh/authorized_keys /home/$username/.ssh/authorized_keys
chown $username /home/$username
chgrp $username /home/$username
chown -R $username /home/$username/.ssh
chgrp -R $username /home/$username/.ssh
# echo "$username:$password" | chpasswd

# ssh config
curl https://raw.githubusercontent.com/motojouya/develop-ec2/main/resources/sshd_config.tmpl -O
sed -e s/{%port%}/$ssh_port/g sshd_config.tmpl > sshd_config.init
cp sshd_config.init /etc/ssh/sshd_config
systemctl restart sshd

# register route53
curl https://raw.githubusercontent.com/motojouya/develop-ec2/main/resources/dyndns.tmpl -O
sed -e "s/{%IP%}/$ip/g;s/{%domain%}/$domain/g" dyndns.tmpl > change_resource_record_sets.json
aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch file:///home/ec2-user/change_resource_record_sets.json

# install nginx and certbot for let's encrypt
cd /etc
cp /home/$username/letsencrypt.tar.gz letsencrypt.tar.gz
tar -xzf letsencrypt.tar.gz
cd /home/ec2-user

yum install -y nginx
curl https://raw.githubusercontent.com/motojouya/develop-ec2/main/resources/http.conf.tmpl -O
sed -e s/{%domain%}/$domain/g http.conf.tmpl > http.conf
cp http.conf /etc/nginx/conf.d/http.conf
systemctl start nginx.service

# git
dnf install -y git
git -v

# install nodejs
yum install https://rpm.nodesource.com/pub_20.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1
npm install -g npx
npm install -g typescript typescript-language-server
npm install -g aws-cdk

# install docker
dnf install -y docker
systemctl enable --now docker
systemctl status docker
usermod -aG docker $username
docker info

sudo dnf install -y docker
sudo systemctl enable --now docker
docker info

DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version
# dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
# dnf --releasever=36 install -y docker-buildx-plugin docker-compose-plugin
# gpasswd -a $username docker
# systemctl restart docker

# pip
# curl -O https://bootstrap.pypa.io/get-pip.py
# python3 get-pip.py
dnf install -y python3 augeas-libs pip
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot
ln -s /opt/certbot/bin/certbot /usr/bin/certbot
# apt install -y software-properties-common
# add-apt-repository -y universe
# add-apt-repository -y ppa:certbot/certbot
# apt update
# apt install -y certbot python-certbot-nginx

# terraform
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform

# # others
# /home/$username/.fzf/install --bin
