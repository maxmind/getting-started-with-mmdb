# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/artful64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
   config.vm.provision "shell", inline: <<-SHELL

      sudo apt-get install -y aptitude

      # Don't do this more than once in an hour
      if [ -z "$(find /var/cache/apt/pkgcache.bin -mmin -60)" ]; then
          sudo aptitude update
          # install 'add-apt-repository'
          sudo aptitude install -y python-software-properties software-properties-common

          sudo apt-add-repository multiverse
          sudo add-apt-repository ppa:maxmind/ppa
          sudo aptitude update
      fi

      # Make subsequent provisioning work if initial install has failed
      sudo rm -f /etc/GeoIP.conf

      # 'make' is part of build-essential
      sudo aptitude install -y build-essential curl geoipupdate libmaxminddb0 libmaxminddb-dev libnet-ssleay-perl mmdb-bin unzip

      # install Perl modules from CPAN
      curl --silent -L https://cpanmin.us | perl - App::cpanminus
      cpanm --notest App::cpm

      # Faster installs via cpm.  Defaults to using cpanfile.
      cd /vagrant
      cpanm --notest https://cpan.metacpan.org/authors/id/M/MA/MAXMIND/MaxMind-DB-Writer-0.300001.tar.gz
      cpm install --without-test

      sudo cp /vagrant/GeoIP.conf /etc/GeoIP.conf
      sudo geoipupdate

      rm -rf /tmp/csv
      mkdir  /tmp/csv
      curl https://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip > /tmp/GeoLite2-City-CSV.zip
      unzip -o /tmp/GeoLite2-City-CSV.zip -d /tmp/csv/
      find /tmp/csv/ -name GeoLite2-City-Locations-en.csv | xargs -I '{}' mv '{}' /vagrant/
      find /tmp/csv/ -name GeoLite2-City-Blocks-IPv4.csv | xargs -I '{}' mv '{}' /vagrant/
  SHELL
end
