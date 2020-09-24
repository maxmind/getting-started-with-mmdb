<!-- vim-markdown-toc GFM -->

* [Before You Start](#before-you-start)
* [Installation](#installation)
  * [Vagrant](#vagrant)
    * [Getting a License Key](#getting-a-license-key)
    * [vagrant up](#vagrant-up)
    * [Re-provision](#re-provision)
  * [Manual Installation](#manual-installation)
    * [Caveat for Windows Users](#caveat-for-windows-users)
    * [Perl](#perl)
    * [libmaxminddb](#libmaxminddb)
    * [cpanminus](#cpanminus)
    * [CPAN Modules](#cpan-modules)
    * [GeoLite2-City](#geolite2-city)

<!-- vim-markdown-toc -->

# Before You Start

This repository is quite old and doesn't represent our most modern tooling. If you'd like to get up and running with our currently recommended tools (written in Go), please read the following article: [https://blog.maxmind.com/2020/09/01/enriching-mmdb-files-with-your-own-data-using-go/
](https://blog.maxmind.com/2020/09/01/enriching-mmdb-files-with-your-own-data-using-go/) If you'd prefer to work with our Perl examples, please read on.

# Installation

## Vagrant

### Getting a License Key

In order to download your databases, create a `.env` file in the root of this directory.

`cp .env-sample .env`

Edit the `.env` file and replace the boilerplate license key with your own. If you need to generate a license key, log in to your MaxMind.com account (or create an account first) and generate a new license key by clicking "My License Key" on the left hand menu.

### vagrant up

If you use [Vagrant](https://www.vagrantup.com/), you can get started easily. After cloning this repository, issue the following command from the top level of the repository:

    vagrant up

If you are starting this Vagrant VM for the first time, you might want to make yourself a sandwich.  Depending on your setup it could take 6-10 minutes before your VM is ready.  Once the provisioning is finished, you can log in to your VM and start running commands.

    vagrant ssh
    cd /vagrant
    perl examples/01-getting-started.pl

If you've followed the instructions above, you are ready to go.

    perl examples/01-getting-started.pl

That's it!  Read on if you want to install things manually.

### Re-provision

If your `vagrant up` does not run to completion you can re-run it via `vagrant provision`. If you are upgrading from an earlier version of this repository, you'll want to `rm -rf local` inside this repository first, so that you'll get a fresh install of Perl modules.

## Manual Installation

### Caveat for Windows Users

`MaxMind::DB::Writer` is not currently supported on Windows Operating Systems.  If you're in a Windows environment, you may want to try setting up the Vagrant VM by following the instructions above.

### Perl

You'll need Perl to run the example code.  Unless you're in a Windows environment, you probably already have Perl installed.  A minimum version of 5.14 is enough to get started with.  You can check your version via `perl --version`.


### libmaxminddb

Before installing any Perl modules you'll need to install [libmaxminddb](https://github.com/maxmind/libmaxminddb).

### cpanminus

[cpm](https://metacpan.org/pod/App::cpm) is probably the easiest Perl install tool to get up and running with.  If you don't already have it, you can install it with a one-liner:

```
curl -fsSL --compressed https://git.io/cpm > /usr/local/bin/cpm
chmod +x /usr/local/bin/cpm
cpm --version
```

We've chosen to install _without_ `sudo`, so that we don't interfere with any modules which the system requires.

### CPAN Modules

Now that we have a tool to install our Perl modules, let's go ahead and install the modules we need to write an MMDB file.  I should add the caveat that we don't currently have Windows support for our writer, so you'll need access to a *nix or Mac OS X environment to play along.  If you do have a Windows machine, an Ubuntu VM or something similar will be just fine.

    cpm install --cpanfile cpanfile

If you're on Mac OS X and the above install fails, you can try forcing a 64 bit architecture:

    ARCHFLAGS="-arch x86_64" cpm install MaxMind::DB::Writer::Tree Net::Works::Network

Now you're ready to start running scripts:

    perl examples/01-getting-started.pl

### GeoLite2-City

You'll need a copy of GeoLite2-City.mmdb somewhere on your filesystem. You can [download](https://dev.maxmind.com/geoip/geoip2/geolite2/) this file manually.  If you need more details on how we set this up, you can look at the `provision` section of the `Vagrantfile` in the GitHub repository.
