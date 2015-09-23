# Building Your Own MMDB Databases for Fun and Profit
If you use a GeoIP database, you're probably familiar with MaxMind's [MMDB format](https://github.com/maxmind/MaxMind-DB/blob/master/MaxMind-DB-spec.md). 

At MaxMind, we created the MMDB format because we needed a format that was very fast and highly portable.  MMDB comes with supported readers in many languages.  In this blog post, we’ll create an MMDB file which contains a whitelist of IP addresses.  This kind of database could be used when allowing access to a VPN or a hosted application.

## Tools You'll Need

The code samples I include here use the [Perl MMDB database writer](https://metacpan.org/pod/MaxMind::DB::Writer) and the [Perl MMDB database reader](https://metacpan.org/pod/MaxMind::DB::Reader).  You'll need to use Perl to write your own MMDB files, but you can read the files with the officially supported [.NET, PHP, Java and Python readers](https://github.com/maxmind?utf8=%E2%9C%93&query=reader) in addition to unsupported third party MMDB readers.  Many are listed on the [GeoIP2 download page](http://dev.maxmind.com/geoip/geoip2/downloadable/). So, as far as deployments go, you're not constrained to any one language when you want to read from the database.

## Following Along

Use [our GitHub repository](https://github.com/maxmind/getting-started-with-mmdb) to follow along with the actual scripts.  Fire up a pre-configured Vagrant VM or just install the required modules manually.

## Getting Started
    
In our example, we want to whitelist some IP addresses to allow them access to a VPN or a hosted application.  For each IP address or IP range, we need to track a few things about the person who is connecting from this IP.
 
 * name
 * development enviroments to which they need access 
 * an arbitrary session expiration time, defined in seconds

To do so, we create the following the file `examples/01-getting-started.pl`

```perl
#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

my $filename = 'users.mmdb';

# Your top level data structure will always be a map (hash).  The MMDB format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

my %types = (
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
    '123.125.71.29/32' => {
        environments => [ 'development', 'staging', 'production' ],
        expires      => 86400,
        name         => 'Jane',
    },
    '8.8.8.8/28' => {
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
open my $fh, '>:raw', $filename;
$tree->write_tree( $fh );
close $fh;

say "$filename has now been created";
```

## The Code in Review

The code consists of three parts:  

### Step 1 
Create a new [MaxMind::DB::Writer::Tree](https://metacpan.org/pod/MaxMind::DB::Writer::Tree) object.  The tree is where the database is stored in memory as it is created.  

```perl
MaxMind::DB::Writer::Tree->new(...)
```

The options we've used are all commented in the script, but there are additional options.  They're all [fully documented](https://metacpan.org/pod/MaxMind::DB::Writer::Tree) as well.  To keep things simple (and easily readable), we used IPv4 to store addresses in this example, but you could also use IPv6.

We haven't used all available types in this script.  For example, we also could have used a `map` to store some of these valued.  You're encouraged to review [the full list of available types](https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES) which can be used in `map_key_type_callback`.

### Step 2
For each IP address or range, we call the `insert_network()` method.  This method takes two arguments.  The first is a [Net::Works::Network](https://metacpan.org/pod/Net::Works::Network) object, which is essentially just a representation of the IP range.  The second is a hash reference of values which describe the IP range.

```perl
$tree->insert_network( $network, $address_for_employee{$address} );
```

We've inserted information about two employees, Jane and Klaus.  They're both on different IP ranges.  You'll see that Jane has access to more environments than Klaus has, but Klaus could theoretically connect from any of 16 different IP addresses (/28) whereas Jane will only connect from one (/32).

### Step 3
Open a filehandle and the write the database to disk.

```perl
open my $fh, '>:raw', 'my-vpn.mmdb';
$tree->write_tree( $fh );
close $fh;
```

## Let's Do This

Now we're ready to run the script.
    
    perl examples/01-getting-started.pl
    
Your output should look something like:

    users.mmdb has now been created
    
You should also see the file mentioned above in the folder from which you ran the script.

## Reading the File

Now that we have our brand new MMDB file. Let's read the information we stored in it.

```perl
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

## File Reading - Review

### Step 1

Ensure that the user has provided an IP address via the command line.

```perl
my $ip = shift @ARGV or die 'Usage: perl examples/02-reader.pl [ip_address]';
```

### Step 2

We create a new [MaxMind::DB::Reader](https://metacpan.org/pod/MaxMind::DB::Reader) object, using the name of the file we just created as the sole argument.

```perl
my $reader = MaxMind::DB::Reader->new( file => 'users.mmdb' );
```

### Step 3

Check the metadata.  This is optional, but here print the description we added to the metadata in the previous script.

```perl
say 'Description: ' . $reader->metadata->{description}->{en};
```

Much more metadata is available in addition to the `description`.  `$reader->metadata` returns a [MaxMind::DB::Metadata](https://metacpan.org/pod/MaxMind::DB::Metadata) which provides much more information about the file you created.

### Step 4

We perform a record lookup and dump it using Data::Printer's handy `np()` method.

```perl
my $record_for_jane = $reader->record_for_address( '123.125.71.29' );
say np $record_for_jane;
```

## Running the Script

Now let's run the script and perform a lookup on Jane's IP address:

    perl examples/02-reader.pl 123.125.71.29
    
Your output should look something like this: 

```perl
vagrant@precise64:/vagrant$ perl examples/02-reader.pl 123.125.71.29
Description: My database of IP data
\ {
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane"
}
```

We see that our `description` and our `Hash` of user data is returned exactly as we initially provided it.  But what about Klaus, is he also in the database?

```
vagrant@precise64:/vagrant$ perl examples/02-reader.pl 8.8.8.0
Description: My database of IP data
\ {
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

It takes time to look up every address individually.  Is there a way to speed things up?  As it happens, there is.

```perl
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


## Iterating: Review

### Step 1

As in the previous example, we create a new `MaxMind::DB::Reader` object.

### Step 2

To dump our data, we pass an anonymous subroutine to the [iterate_search_tree()  method](https://metacpan.org/pod/MaxMind::DB::Reader#reader-iterate_search_tree-data_callback-node_callback).  (This method can actually take two callbacks, but the second callback is for debugging the actual nodes in the tree -- that's too low level for our purposes today).

We've appropriately named the three arguments which are passed to the callback, so there's not much more to say about them.  Let's look at the output.

```
vagrant@precise64:/vagrant$ perl examples/03-iterate-search-tree.pl
8.8.8.0/28
\ {
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus"
}
123.125.71.29/32
\ {
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane"
}
```

The output shows the first IP in each range (note that Jane's IP is just a "range" of one) and then displays the user data with which we're now familiar.


## The Mashup

To extend our example, let’s take the data from an existing GeoIP2 database and combine it with our custom MMDB file.

If you're using the `Vagrant` VM, you have a copy of `GeoLite2-City.mmdb` in `/user/share/GeoIP`.  If not, you may need to [download this file](https://dev.maxmind.com/geoip/geoip2/geolite2/) or use [geoipupdate](https://dev.maxmind.com/geoip/geoipupdate/).  For more details on how to set this up, you can look at the `provision` section of the `Vagrantfile` in the GitHub repository.

You can take any number of fields from existing MaxMind databases to create your own custom database.  In this case, let's extend our existing database by adding `city`, `country` and `time_zone` fields for each IP range.

```perl
#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use GeoIP2::Database::Reader;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

my $filename = 'users.mmdb';
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

    # "database_type" is an arbitrary string describing the database.  At
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

    # let the writer handle merges of IP ranges. if we don't set this then the
    # default behaviour is for the last network to clobber any overlapping
    # ranges.
    merge_record_collisions => 1,

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 24,
);

my %address_for_employee = (
    '123.125.71.29/32' => {
        environments => [ 'development', 'staging', 'production' ],
        expires      => 86400,
        name         => 'Jane',
    },
    '8.8.8.8/28' => {
        environments => [ 'development', 'staging' ],
        expires      => 3600,
        name         => 'Klaus',
    },
);

for my $range ( keys %address_for_employee ) {

    my $user_metadata = $address_for_employee{$range};

    # Iterate over network and insert IPs individually
    my $network = Net::Works::Network->new_from_string( string => $range );
    my $iterator = $network->iterator;

    while ( my $address = $iterator->() ) {
        my $ip = $address->as_ipv4_string;
        my $model = $reader->city( ip => $ip );

        if ( $model->city->name ) {
            $user_metadata->{city} = $model->city->name;
        }
        if ( $model->country->name ) {
            $user_metadata->{country} = $model->country->name;
        }
        if ( $model->location->time_zone ) {
            $user_metadata->{time_zone} = $model->location->time_zone;
        }
        $tree->insert_network( $network, $user_metadata );
    }
}

# Write the database to disk.
open my $fh, '>:raw', $filename;
$tree->write_tree( $fh );
close $fh;

say "$filename has now been created";
```

Now, when we iterate of the search tree, we'll see that the data has been augmented with the new fields.

```
vagrant@precise64:/vagrant$ perl examples/03-iterate-search-tree.pl
8.8.8.0/28
\ {
    city           "Mountain View",
    country        "United States",
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus",
    time_zone      "America/Los_Angeles"
}
123.125.71.29/32
\ {
    city           "Beijing",
    country        "China",
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane",
    time_zone      "Asia/Shanghai"
}
```
 
## Adding GeoLite2-City Data (Review)

To extend our example we make two additions to our original file:

### Step 1
We create a new reader object:

```perl
my $reader   = GeoIP2::Database::Reader->new(
    file    => '/usr/share/GeoIP/GeoLite2-City.mmdb',
    locales => ['en'],
);
```

Note that this file may be in a different location if you're not using `Vagrant`.  Adjust accordingly.

### Step 2

Now, we take our existing data so that we can augment it with GeoIP2 data.

```perl
    my $user_metadata = $address_for_employee{$range};

    # Iterate over network and insert IPs individually
    my $network = Net::Works::Network->new_from_string( string => $range );
    my $iterator = $network->iterator;

    while ( my $address = $iterator->() ) {
        my $ip = $address->as_ipv4_string;
        my $model = $reader->city( ip => $ip );
        
        if ( $model->city->name ) {
            $user_metadata->{city} = $model->city->name;
        }
        if ( $model->country->name ) {
            $user_metadata->{country} = $model->country->name;
        }
        if ( $model->location->time_zone ) {
            $user_metadata->{time_zone} = $model->location->time_zone;
        }
        $tree->insert_network( $network, $user_metadata );
    }
```

As in our first example, we're create a new `Net::Works::Network` object.  However, in this case we are going to insert each individual IP in the range.  The reason for this is that we don't know if our IP ranges match the ranges in the GeoLite2 database.  If we just rely on using the reader data for some arbitrary IP in the range, we can't be 100% sure that this is representative of all other IPs in the range.  If we insert each IP in the range, we don't need to rely on the assumption that the data for a random IP will be consistent across our ranges.

In order for this to work, we set `merge_record_collisions => 1` when we created the `MaxMind::DB::Writer::Tree` object.  This allows the writer to be smart about merging ranges rather than letting the last range to be added clobber any overlapping addresses.

Note that this approach is fine for a small database, but it likely will not scale well in terms of creating speed for a database with a large number of records.  If you're looking to create a very large database and speed is an issue, you are encouraged to look into using the MaxMind CSVs to seed your database.  Alternatively, you could first check the IP ranges in GeoLite2-City-Blocks-IPv4.csv to check for any overlapping ranges before inserting.  If there are no overlaps, you can insert the entire range at once rather than individual IP addresses.

Iterating over a network is trivial.

```perl
    my $network = Net::Works::Network->new_from_string( string => $range );
    my $iterator = $network->iterator;

    while ( my $address = $iterator->() ) {
        my $ip = $address->as_ipv4_string;
        ...
    }
```
    
The next step is to look up an IP address using the reader.

```perl
my $model = $reader->city( ip => $ip );
```

We need to pass the model a `string` rather than an `object`, so we call the `as_ipv4_string()` method.

Next we add new keys to `Hash`.  The new keys are `country`, `city` and `time_zone`.  Note that we only add them if they exist.  If we try to add an `undefined` value to the `Hash`, it an exception will be thrown.

Now, let's see what we get.

```
vagrant@precise64:/vagrant$ perl examples/03-iterate-search-tree.pl
8.8.8.0/28
\ {
    city           "Mountain View",
    country        "United States",
    environments   [
        [0] "development",
        [1] "staging"
    ],
    expires        3600,
    name           "Klaus",
    time_zone      "America/Los_Angeles"
}
123.125.71.29/32
\ {
    city           "Beijing",
    country        "China",
    environments   [
        [0] "development",
        [1] "staging",
        [2] "production"
    ],
    expires        86400,
    name           "Jane",
    time_zone      "Asia/Shanghai"
}
```

Even though we inserted Klaus's addresses individually, we can see that the writer did the right thing and merged the addresses into an appropriately sized network.

## Deploying our Application

Now we're at the point where we can make use of our database.  With just a few lines of code you can now use your MMDB file to assist in the authorization of your application or VPN users.  For example, you might include the following lines in a class which implements your authentication.


```perl
use MaxMind::DB::Reader;

my $reader = MaxMind::DB::Reader->new( file => '/path/to/users.mmdb' );

sub is_ip_valid {
    my $self   = shift;
    my $ip     = shift;

    my $record = $reader->record_for_address( $ip );
    return 0 unless $record;

    $self->set_session_expiration( $record->{expires} );
    $self->set_time_zone( $record->{time_zone} ) if $record->{time_zone};
    return 1;
}
```
Here's a quick summary of what's going on.

* As part of your deployment you'll naturally need to include your `users.mmdb` file, stored in the location of your choice.
* You'll need to create a `MaxMind::DB::Reader` object to perform the lookup.
* If the `$record` is undef, the IP could not be found.
* If the IP is found, you can set a session expiration.
* If the IP is found, you can also set a time zone for the user.  Keep in mind that it's possible that the `time_zone` key does not exist, so it's important that you don't assume it will always be available.


## Pro Tips

### Including the Contents of an Entire MaxMind DB

To include the contents of an entire GeoIP2 database rather than selected data points, you have a couple of options for iterating over a database in Perl.

#### MaxMind::DB::Reader

A very simple way to get started is to iterate over the search tree using `MaxMind::DB::Reader` as we did in `examples/03-iterate-search-tree.pl`.  However, note that iterating over the entire tree using the Perl reader can be quite slow.

#### Parsing a CSV

This requires slightly more logic, but just reading a CSV file line by line will give you a significant boost in speed.  Free downloads of CSV files for GeoLite2 City and GeoLite2 Country [are available from MaxMind.com](https://dev.maxmind.com/geoip/geoip2/geolite2/)  If you're using the Vagrant VM, you'll find `GeoLite2-City-Blocks-IPv4.csv` and `GeoLite2-City-Locations-en.csv` already in your `/vagrant` directory. `examples/06-read-csv.pl` will give you a head start on parsing these CSVs.

### Insert Order, Merging and Overwriting

In our simple examples, we haven't dealt with any overlapping IP ranges, but it's important to understand `MaxMind::DB::Writer`'s configurable behaviour for inserting ranges.  Please see our documentation on [Insert Order, Merging and Overwriting](https://metacpan.org/pod/MaxMind::DB::Writer::Tree#Insert-Order-Merging-and-Overwriting) so that you can choose the correct behaviour for any overlapping IP ranges you may come across.

## Taking This Further

Today we've shown how you can create your own MMDB databases and augment it with data from a GeoLite2-City database.  We've only included a few data points, but MaxMind databases contain much more data you can use to build a solution to meet your business requirements.

