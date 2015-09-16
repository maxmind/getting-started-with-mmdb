Recently I was reading a discussion online which touched on what the options are for storing information which is specific to IP addresses and IP ranges.  There are really lots of ways to do this, each with its own pros and cons.  Some of the possible formats are:

 * plain text
 * CSV or spreadsheet
 * relational databases (Postgres, MySQL/MariaDB, etc)
 * document stores (MongoDB, Elasticsearch, etc)

 Depending on your use case, any of the above might be a good fit for you.  Having said that, today I want to introduce one more way to store IP address and range-specific data: The [MaxMindDB format](https://github.com/maxmind/MaxMind-DB/blob/master/MaxMind-DB-spec.md).
 
One big reason you may want to use MaxMindDB is that you won't have to reinvent this particular wheel.

 * You can use our officially supported [Perl MMDB database writer](https://metacpan.org/pod/MaxMind::DB::Writer)
 * You have access to our officially supported MMDB readers in [Perl, .NET, PHP, Java or Python](https://github.com/maxmind?utf8=%E2%9C%93&query=reader)
 * You may also choose to use a third party MMDB reader.  Many are listed on the [GeoIP2 download page](http://dev.maxmind.com/geoip/geoip2/downloadable/).
 
 If you go this route you won't have to solve all of the problems which we've already solved for you.  Also, MMDB format is fast and portable.  It's also very easy to use.  That's what we're going to demonstrate today.
 
 First, let's install our tools to read and write a custom MMDB file.  Our language of choice for building the database is Perl, but keep in mind that you have many choices for readers in different languages.  You do not have to deploy your databases using a Perl reader, unless that's your preference.
 
[cpanm](https://metacpan.org/pod/App::cpanminus) is probably the easiest Perl install tool to get up and running with.  If you don't already have it, you can install it with a one-liner:

    curl -L https://cpanmin.us | perl - App::cpanminus

We've chosen to install _without_ `sudo`, so that we don't interfere with any modules which the system requires.

Now that we have a tool to install our Perl modules, let's go ahead and install the modules we need to write an MMDB file.  I should add the caveat that we don't currently have Windows support for our writer, so you'll need access to a *nix or Mac OS X environment to play along.  If you do have a Windows machine, an Ubuntu VM or something similar will be just fine.

    cpanm MaxMind::DB::Writer::Tree Net::Works::Network Data::Printer
    
If you're on Mac OS X and the above install fails, you can try forcing a 64 bit architecture:

    ARCHFLAGS="-arch x86_64" cpanm MaxMind::DB::Writer::Tree Net::Works::Network
    
Now, let's try to create a very simple database.

```
#!/usr/bin/env perl

use strict;
use warnings;

use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

# Your top level data structure will always be a map (hash).  The mmdb format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

my %types = (
    color => 'utf8_string',
    dogs  => [ 'array', 'utf8_string' ],
    size  => 'uint16',
);

my $tree = MaxMind::DB::Writer::Tree->new(

    # "database_type" is some aritrary string describing the database.  AVt
    # MaxMind we use strings like 'GeoIP2-City', 'GeoIP2-Country', etc.

    database_type => 'My-IP-Data',

    # "description" is a hashref where the keys are language names and the
    # values are descriptions of the database in that language.

    description =>
        { en => 'My database of IP data', fr => 'Mon Data de IP', },

    # "ip_version" can be either 4 or 6

    ip_version            => 4,

    map_key_type_callback => sub { $types{ $_[0] } },

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size           => 24,
);

# Create one network and insert it into our database
my $network = Net::Works::Network->new_from_string( string => '4.4.4.4/32' );

$tree->insert_network(
    $network,
    {   color => 'blue',
        dogs  => [ 'Fido', 'Ms. Pretty Paws' ],
        size  => 42,
    },
);

# Write the database to disk.
open my $fh, '>:raw', 'example.mmdb';
$tree->write_tree( $fh );
close $fh;
```

Now, let's save our program and run it.

    mkdir -p examples
    # save as examples/01-getting-started.pl
    
    perl examples/01-getting-started.pl
    
If you don't see any output, then your database has been successfully built.  Check the folder for a `example.mmdb` file.

Now, let's try to read the file which we just created.

```
#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use MaxMind::DB::Reader;
use Net::Works::Address;

my $reader = MaxMind::DB::Reader->new( file => 'example.mmdb' );

say 'Description: ' . $reader->metadata->{description}->{en};

my $record = $reader->record_for_address( '4.4.4.4' );
say np $record;
```

Save the script above as `examples/02-reader.pl` and run it.

    perl examples/02-reader.pl
    
Your output should look something like this: 

```
$ perl examples/02-reader.pl
Description: My database of IP data
\ {
    color => "blue",
    dogs  => [
        [0] "Fido",
        [1] "Ms. Pretty Paws",
    ],
    size  => 42,
}
```

 