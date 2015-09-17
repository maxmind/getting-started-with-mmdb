# Installation

## Vagrant

If you use [Vagrant](https://www.vagrantup.com/), you can get started easily. After cloning this repository, `chdir` to the top directory.  Then issue the following commands:

    vagrant up
    
Now you (hopefully) have a running VM with everything you need already installed.  You can now log in to your VM and start running commands.
    
    vagrant ssh
    cd /vagrant
    perl examples/01-getting-started.pl

## Manual Installation

### libmaxminddb

First you'll need to install [libmaxminddb](https://github.com/maxmind/libmaxminddb)

### cpanminus

[cpanm](https://metacpan.org/pod/App::cpanminus) is probably the easiest Perl install tool to get up and running with.  If you don't already have it, you can install it with a one-liner:

    curl -L https://cpanmin.us | perl - App::cpanminus

We've chosen to install _without_ `sudo`, so that we don't interfere with any modules which the system requires.

### CPAN Modules

Now that we have a tool to install our Perl modules, let's go ahead and install the modules we need to write an MMDB file.  I should add the caveat that we don't currently have Windows support for our writer, so you'll need access to a *nix or Mac OS X environment to play along.  If you do have a Windows machine, an Ubuntu VM or something similar will be just fine.

    cpanm MaxMind::DB::Writer::Tree Net::Works::Network Data::Printer
    
If you're on Mac OS X and the above install fails, you can try forcing a 64 bit architecture:

    ARCHFLAGS="-arch x86_64" cpanm MaxMind::DB::Writer::Tree Net::Works::Network
    
Now you're ready to start running scripts:

    perl /vagrant/examples/examples/01-getting-started.pl
