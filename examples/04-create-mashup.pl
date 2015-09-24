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

# Your top level data structure will always be a map (hash).  The MMDB format
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
