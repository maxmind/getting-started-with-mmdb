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

# Iterate

$reader->iterate_search_tree(
    sub {
        my $ip_as_integer = shift;
        my $mask_length   = shift;
        my $data          = shift;

        my $address = Net::Works::Address->new_from_integer( integer => $ip_as_integer );
        say $address->as_ipv4_string;
    }
);
