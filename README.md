# Installation

## Vagrant

If you use [Vagrant](https://www.vagrantup.com/), you can get started easily. After cloning this repository, issue the following command from the top level of the repository:

    vagrant up
    
If you are starting this Vagrant VM for the first time, you might want to make yourself a sandwich.  Depending on your setup it could take 6-10 minutes before your VM is ready.  Once the provisioning is finished, you can log in to your VM and start running commands.
    
    vagrant ssh
    cd /vagrant
    perl examples/01-getting-started.pl

If you've followed the instructions above, you are ready to go.

    perl examples/01-getting-started.pl

That's it!  Read on if you want to install things manually.

## Manual Installation

### Caveat for Windows Users

`MaxMind::DB::Writer` is not currently supported on Windows Operating Systems.  If you're in a Windows environment, you may want to try setting up the Vagrant VM by following the instructions above.

### Perl

You'll need Perl to run the example code.  Unless you're in a Windows environment, you probably already have Perl installed.  A minimum version of 5.14 is enough to get started with.  You can check your version via `perl --version`.


### libmaxminddb

Before installing any Perl modules you'll need to install [libmaxminddb](https://github.com/maxmind/libmaxminddb).

### cpanminus

[cpanm](https://metacpan.org/pod/App::cpanminus) is probably the easiest Perl install tool to get up and running with.  If you don't already have it, you can install it with a one-liner:

    curl -L https://cpanmin.us | perl - App::cpanminus

We've chosen to install _without_ `sudo`, so that we don't interfere with any modules which the system requires.

### CPAN Modules

Now that we have a tool to install our Perl modules, let's go ahead and install the modules we need to write an MMDB file.  I should add the caveat that we don't currently have Windows support for our writer, so you'll need access to a *nix or Mac OS X environment to play along.  If you do have a Windows machine, an Ubuntu VM or something similar will be just fine.

    cpanm Devel::Refcount MaxMind::DB::Reader::XS MaxMind::DB::Writer::Tree Net::Works::Network GeoIP2 Data::Printer
    
If you're on Mac OS X and the above install fails, you can try forcing a 64 bit architecture:

    ARCHFLAGS="-arch x86_64" cpanm MaxMind::DB::Writer::Tree Net::Works::Network
    
Now you're ready to start running scripts:

    perl examples/01-getting-started.pl

### GeoLite2-City

You'll need a copy of GeoLite2-City.mmdb somewhere on your filesystem. You may need to download this file either via [geoipupdate](https://dev.maxmind.com/geoip/geoipupdate/) or by [downloading](https://dev.maxmind.com/geoip/geoip2/geolite2/) the file manually.  If you need more details on how we set this up, you can look at the `provision` section of the `Vagrantfile` in the GitHub repository.
