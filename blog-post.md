# Building Your Own MMDB Databases for Fun and Profit
If you use a GeoIP database, you're probably familiar with MaxMind's [MMDB format](https://github.com/maxmind/MaxMind-DB/blob/master/MaxMind-DB-spec.md). In this blog post, I'd like to provide an example of the benefits of using it to create your own custom MMDB databases.  

## Available Tools

The code samples we're using will use the [Perl MMDB database writer](https://metacpan.org/pod/MaxMind::DB::Writer) and the [Perl MMDB database reader](https://metacpan.org/pod/MaxMind::DB::Reader).  You'll need to use Perl to write your own MMDB files, but you there are also officially supported [.NET, PHP, Java and Python readers](https://github.com/maxmind?utf8=%E2%9C%93&query=reader) in addition to unsupported third party MMDB readers.  Many are listed on the [GeoIP2 download page](http://dev.maxmind.com/geoip/geoip2/downloadable/). So, as far as deployments go, you're not constrained to any one language when you want to read from the database.

## Getting the Code

If you want to follow along with the actual scripts, you can use [our GitHub repository](https://github.com/oalders/mmdb-getting-started).  You can use it to fire up a pre-configured Vagrant VM or just install the required modules manually.

## Getting Started
    
Let's start with a very simple example.  Let's say you want to whitelist some IP addresses to allow them access to your VPN.  For each IP address or IP range, we'll want to track a few things about the person who is connecting from this IP.
 
 * their name
 * their country
 * the development enviroments they should have access to 
 * some arbitrary session expiration time, defined in seconds

Using MMDB to store your data, you might do something like this.  Our code will be in a file called `examples/01-getting-started.pl`

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
    country      => 'utf8_string',
    environments => [ 'array', 'utf8_string' ],
    expires      => 'uint32',
    name         => 'utf8_string',
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
    ip_version => 4,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub { $types{ $_[0] } },

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 24,
);

my %address_for_employee = (
    '4.4.4.4/32' => {
        country      => 'US',
        environments => [ 'development', 'staging', 'production' ],
        expires      => 86400,
        name         => 'Jane',
    },
    '8.8.8.8/28' => {
        country      => 'US',
        environments => [ 'development', 'staging' ],
        expires      => 3600,
        name         => 'Klaus',
    },
);

for my $address ( keys %address_for_employee ) {

    # Create one network and insert it into our database
    my $network = Net::Works::Network->new_from_string( string => $address );

    $tree->insert_network( $network, $address_for_employee{$address} );
}

# Write the database to disk.
open my $fh, '>:raw', 'my-vpn.mmdb';
$tree->write_tree( $fh );
close $fh;

```

## The Breakdown

There are basically 3 parts to the code.  

### Step 1 
Create a new [MaxMind::DB::Writer::Tree](https://metacpan.org/pod/MaxMind::DB::Writer::Tree) object.  The tree is where the database is stored in memory while we're creating it.  

`MaxMind::DB::Writer::Tree->new(...)`

The options we've used are all documented inside of the script.  There are other options as well.  They're all [fully documented](https://metacpan.org/pod/MaxMind::DB::Writer::Tree).  To keep things simple (and easily readable), we've used IPv4 to store addresses in this example, but we also could have used IPv6.

The `map_key_type_callback` is optional, but you're encouraged to use it in order to ensure the consistency of the data you're inserting.

### Step 2
For each IP address or range, we call the `insert_network()` method.  This method takes two arguments.  The first is a [Net::Works::Network](https://metacpan.org/pod/Net::Works::Network) object, which is essentially just a representation of the IP range.  The second is a `Hash` of values which describe the IP range.

`$tree->insert_network( $network, $address_for_employee{$address} );`

### Step 3
Open a filehandle and the write the database to disk.

```
open my $fh, '>:raw', 'my-vpn.mmdb';
$tree->write_tree( $fh );
close $fh;
```

## Let's Do This

Now we're ready to run this script.
    
    perl examples/01-getting-started.pl
    
Your output should look something like:

    users.mmdb has now been created
    
You should also see the file mentioned above in the folder from which you ran the script.  That's it.  Easy, right?

## From Writing to Reading

We've got our brand new MMDB file. Now, let's try to read the information we just stored in it.

```
#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use MaxMind::DB::Reader;
use Net::Works::Address;

my $ip = shift @ARGV or die 'Usage: perl examples/02-reader.pl [ip_address]';

my $reader = MaxMind::DB::Reader->new( file => 'users.mmdb' );

say 'Description: ' . $reader->metadata->{description}->{en};

my $record = $reader->record_for_address( $ip );
say np $record;
```

## The Breakdown

### Step 1

Ensure that the user has provided an IP address via the command line.

### Step 2

We create a new [MaxMind::DB::Reader](https://metacpan.org/pod/MaxMind::DB::Reader) object, using the name of the file we just created as the sole argument.

### Step 3

Check the metadata.  This is entirely optional, but here we check to ensure that the description which we added to the metadata in the previous script is there.  

    say 'Description: ' . $reader->metadata->{description}->{en};

Beyond the `description`, there is much more metadata to be had.  `$reader->metadata` returns a [MaxMind::DB::Metadata](https://metacpan.org/pod/MaxMind::DB::Metadata) which can give you much more information about the file you just creatd.

### Step 4

We perform a record lookup and dump it using Data::Printer's handy `np()` method.

    my $record_for_jane = $reader->record_for_address( '4.4.4.4' );
    say np $record_for_jane;

## Let's Do This

Let's actually run this script:

    perl examples/02-reader.pl 4.4.4.4
    
Your output should look something like this: 

```
Description: My database of IP data
\ {
    country        "US",
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane"
}
```

We see that our `description` and our `Hash` of user data is returned exactly as we initially provided it.  But what about Klaus, is he also in the database?  Sure:

```
vagrant@precise64:/vagrant$ perl examples/02-reader.pl 8.8.8.0
Description: My database of IP data
\ {
    country        "US",
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus"
}
vagrant@precise64:/vagrant$ perl examples/02-reader.pl 8.8.8.15
Description: My database of IP data
\ {
    country        "US",
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus"
}
vagrant@precise64:/vagrant$ perl examples/02-reader.pl 8.8.8.16
Description: My database of IP data
undef
```

We gave Klaus an IP range of `8.8.8.8/28`, which translates to `8.8.8.0 to 8.8.8.15`.  You can see that when we get to `8.8.8.16` we get an `undef` response, because there is no record at this address.

## Iterating Over the Search Tree

What if we don't want to look up every address individually.  Is there a way to speed things up?  As it happens, there is.

```
#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use MaxMind::DB::Reader;
use Net::Works::Address;

my $reader = MaxMind::DB::Reader->new( file => 'users.mmdb' );

$reader->iterate_search_tree(
    sub {
        my $ip_as_integer = shift;
        my $mask_length   = shift;
        my $data          = shift;

        my $address = Net::Works::Address->new_from_integer(
            integer => $ip_as_integer );
        say join '/', $address->as_ipv4_string, $mask_length;
        say np $data;
    }
);
```


## The Breakdown

### Step 1

As in the previous example, we create a new `MaxMind::DB::Reader` object.

### Step 2

All we need to do in order to dump our data is to pass an anonymous subroutine to the [iterate_search_tree()  method](https://metacpan.org/pod/MaxMind::DB::Reader#reader-iterate_search_tree-data_callback-node_callback).  (This method can actually take two callbacks, but the second callback is for debugging the actual nodes in the tree -- that's too low level for our purposes today).

We've named the 3 arguments which are passed to the callback appropriate, so there's not much more to say about them.  Let's see the output.

```
vagrant@precise64:/vagrant$ perl examples/03-iterate-search-tree.pl
4.4.4.4/32
\ {
    country        "US",
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane"
}
8.8.8.0/28
\ {
    country        "US",
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus"
}
```

The output shows us the first IP in each range (keep in mind that Jane's IP is actually just a "range" of one) and then displays the user data which we're now quite familiar with.


## The Mashup

Should we try to make this a little more complicated?  What would happen if we tried to take data from an existing GeoIP2 database and combine it with our custom MMDB file?

If you're using the `Vagrant` VM, then you'll already have a copy of `GeoLite2-City.mmdb` in your `/user/share/GeoIP` folder.  If you're doing this some other way, you may need to download this file either via [geoipupdate](https://dev.maxmind.com/geoip/geoipupdate/) or by [downloading](https://dev.maxmind.com/geoip/geoip2/geolite2/) the file manually.  If you need more details on how we set this up, you can look at the `provision` section of the `Vagrantfile` in the GitHub repository.

```
#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use GeoIP2::Database::Reader;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

my $filename = 'users.mmdb';

# This is the default GeoIP folder on the Ubuntu install 
my $reader   = GeoIP2::Database::Reader->new(
    file    => '/usr/share/GeoIP/GeoLite2-City.mmdb',
    locales => ['en'],
);

# Your top level data structure will always be a map (hash).  The mmdb format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

my %types = (
    city         => 'utf8_string',
    country      => 'utf8_string',
    environments => [ 'array', 'utf8_string' ],
    expires      => 'uint32',
    name         => 'utf8_string',
    time_zone    => 'utf8_string',
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
    ip_version => 4,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub { $types{ $_[0] } },

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 24,
);

my %address_for_employee = (
    '4.4.4.4/32' => {
        country      => 'US',
        environments => [ 'development', 'staging', 'production' ],
        expires      => 86400,
        name         => 'Jane',
    },
    '8.8.8.8/28' => {
        country      => 'US',
        environments => [ 'development', 'staging' ],
        expires      => 3600,
        name         => 'Klaus',
    },
);

for my $address ( keys %address_for_employee ) {

    # Create one network and insert it into our database
    my $network = Net::Works::Network->new_from_string( string => $address );
    my $model = $reader->city( ip => $network->first->as_ipv4_string );

    my $user_metadata = $address_for_employee{$address};
    
    # Create a mashup using an existing GeoIP2 database
    if ( $model->city->name ) {
        $user_metadata->{city} = $model->city->name;
    }
    if ( $model->location->time_zone ) {
        $user_metadata->{time_zone} = $model->location->time_zone;
    }
    $tree->insert_network( $network, $user_metadata );
}

# Write the database to disk.
open my $fh, '>:raw', $filename;
$tree->write_tree( $fh );
close $fh;

say "$filename has now been created";
```

```
vagrant@precise64:/vagrant$ perl examples/03-iterate-search-tree.pl
4.4.4.4/32
\ {
    country        "US",
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane"
}
8.8.8.0/28
\ {
    city           "Mountain View",
    country        "US",
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus",
    time_zone      "America/Los_Angeles"
}
```
 
## The Breakdown

You'll notice that we've just built on top of the file in our first example.  There are two additions.

### Step 1
We create a new reader object:

```
my $reader   = GeoIP2::Database::Reader->new(
    file    => '/usr/share/GeoIP/GeoLite2-City.mmdb',
    locales => ['en'],
);
```

This file may be in a different location if you're not using `Vagrant`.  If you download it manually, feel free to put it whereever you want.

### Step 2

Now, we just need to take our existing data so that we can augment it with GeoIP2 data.

```
    my $network = Net::Works::Network->new_from_string( string => $address );
    my $model = $reader->city( ip => $network->first->as_ipv4_string );

    my $user_metadata = $address_for_employee{$address};
    
    # Create a mashup using an existing GeoIP2 database
    if ( $model->city->name ) {
        $user_metadata->{city} = $model->city->name;
    }
    if ( $model->location->time_zone ) {
        $user_metadata->{time_zone} = $model->location->time_zone;
    }
```

As in our first example, we're creating a new `$network`.

    my $network = Net::Works::Network->new_from_string( string => $address );
    
Now, we need to look up an IP address using the reader.  The reader expects a single IP and not a range.  We could get it by splitting our original key on `/`, but in this case we'll show how you can do it with a `$network` object.

    my $model = $reader->city( ip => $network->first->as_ipv4_string );

All we're doing here is asking for the first IP in the range.  We need to pass the model a `string` rather than an `object`, so we call the `as_ipv4_string()` method.

At this point we just add new keys to `Hash`.  Our new keys are `city` and `time_zone`.  Note that we only add them if they exist.  If we try to add an `undefined` value to the `Hash`, then an exception will be thrown.

Now, let's see what we get.

```
vagrant@precise64:/vagrant$ perl examples/03-iterate-search-tree.pl
4.4.4.4/32
\ {
    country        "US",
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane"
}
8.8.8.0/28
\ {
    city           "Mountain View",
    country        "US",
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus",
    time_zone      "America/Los_Angeles"
}
```

Now, that looks a little bit better.  Note that we didn't find a city or time zone for Jane, so they haven't been included with her metadata.  GeoIP2 contains a lot of data, but there are some coverage gaps, so you'll need to allow for those when putting your custom database together.

## Taking This Further

Today we've shown how you can make your own MMDB databases and how you can augment them with data from a GeoIP2-City database.  We've only included a couple of data points, but MaxMind products contain much more information which you could potentially blend into your own database so that you can build something for your own needs.

If you wanted to include the contents of an entire GeoIP2 database rather than just a select few, look into iterating over the search tree as we did in `examples/03-iterate-search-tree.pl`.

If you are inserting both IP addresses and ranges, please see our documentation on [Insert Order, Merging and Overwriting](https://metacpan.org/pod/MaxMind::DB::Writer::Tree#Insert-Order-Merging-and-Overwriting) so that you can choose the correct behaviour for any overlapping IP ranges you may come across.