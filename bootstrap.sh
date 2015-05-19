#!/usr/bin/env bash

################################################################
## This file for setting up a development virtual machine and referenced in Vagrantfile
################################################################

# Use Google name server for performance
echo nameserver 8.8.8.8 | sudo tee /etc/resolv.conf

# Install apt dependencies
sudo apt-get update
sudo apt-get install -y memcached redis-server git postgresql postgresql-contrib libpq-dev libxslt-dev libxml2-dev nodejs libicu-dev

# Install Ruby via RVM
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -sSL https://get.rvm.io | bash
echo "source $HOME/.rvm/scripts/rvm" >> ~/.bash_profile
echo "cd /vagrant" >> ~/.bash_profile
source $HOME/.rvm/scripts/rvm
rvm install 2.1

# Install Gems
cd /vagrant
gem install --no-rdoc --no-ri bundler
echo 'gem: --no-document' >> ~/.gemrc
bundle config gems.contribsys.com $1:$2
bundle install

# Use example config files
cp config/config.example.yml config/config.yml
cp config/cloudinary.example.yml config/cloudinary.yml
cp config/database.example.yml config/database.yml

# Use localhost:3000 as default url (can cause SSL cert conflicts, but allows TheKey login)
sed -i 's/mpdx.localhost:3000/localhost:3000/g' config/environments/development.rb

# Create Postgres User
sudo -u postgres psql -c "CREATE ROLE mpdx WITH CREATEDB LOGIN PASSWORD 'mpdx'"

# Create and seed databases
rake db:setup
