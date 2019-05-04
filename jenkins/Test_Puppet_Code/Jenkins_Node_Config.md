#######################################################

Where to place tar'd jobs
=========================
/var/lib/jenkins/jobs

### Here are the steps to configure jenkins server.
-  Must have a ubuntu 14.04 Server with sudo access
-  Internet Connectivity
-  HTTP_PORT=8080 Open
- Follow the below to setup jenins.

```
sudo apt-get update
sudo apt-get install curl zlib1g-dev build-essential libssl-dev libreadline-dev  libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev  python-software-properties libffi-dev rbenv -y ;
```

Must haves on the Jenkins  server :
- ruby >= 2.3
- docker
- Puppet >= 3.8
- Git >= 2.10

```
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable --rails
source /usr/local/rvm/scripts/rvm
rvm list

```
Switch to root or sudo user.

```
echo -ne '\n' | sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git -y
wget -qO- https://get.docker.com/ | sh
ruby -v
git --version
docker --version
sudo reboot
```

##### Installations
1. login to the server
2. Switch to jenkins user and generate SSH KEYS using below commands:

```
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update
apt-get install jenkins
```
```
passwd jenkins
usermod -aG docker jenkins
su - jenkins
ssh-keygen  -t rsa
usermod -a -G sudo jenkins # as root
id jenkins  ####### Verify the Jenkins sudo group
visudo   ######## Add the NOPASSWD Entry : " %sudo	ALL=(ALL:ALL) NOPASSWD:ALL "
```

Switch to *jenkins* user
```
cd /tmp && cat > Gemfile
## add the following
######
source "https://rubygems.org"
gem 'rake'
gem 'serverspec'
gem 'puppet'
gem 'kitchen-docker'
gem 'kitchen-puppet'
gem 'test-kitchen'
gem 'kitchen-verifier-serverspec'
#######
ctrl+d

bundle install
```

NOTE!!: AFTER THIS STAGE - RSYNC THE FILES FROM ONE SERVER TO OTHER
/var/lib/jenkins

For 2nd server, set SSH key in BitBucket
Set SSH keys in foreman

SSH TO PRIMARY ACTIVE JENKINS
rsync -e "ssh -o StrictHostKeyChecking=no" -rvh --delete --exclude '.bash_history' \
--exclude 'logs' --exclude '.ssh' --exclude '.viminfo' \
--exclude '.cache' ./  jenkins@10.99.212.93:/var/lib/jenkins/

### Jenkins version :   2.19.1

Login to jenkins on UI, fill the password using below command :
```
cat /var/lib/jenkins/secrets/initialAdminPassword
```
Then Install the Plugins mentioned as below :
1. Click on Install by selection.
2. By default fewer must have been installed, dont uncheck them.
3. Install the below one's listed :
- Dashboard View
- BitBucket plugins
- Conditional BuildStep Plugin
- Git Parameter plugins
- Github plugins
- Parameterized Trigger plugins
- Role Base Auth Strategy
- ruby-runtime
- Workspace cleanup plugin.
- Build Cause Run Condition plugin
- Extended Choice Parameter plugins
- Run Condition Extras plugins
- Run Selector plugins
- user build vars plugins
- Job Import Plugin

Restart the Jenkins server

#### Setup the BitBucket and JIRA
We require a Bitbucker server with >+ 4.9 version and make sure the requirements are met :
- Keys should be setup with read access for Jenkins user in bitbucket and verify them by once cloning the repo manually.
- Add a REST based Add on in JIRA for CURL calls.
