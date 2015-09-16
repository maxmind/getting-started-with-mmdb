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
