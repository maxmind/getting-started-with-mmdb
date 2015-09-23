#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer; # exports the np() function
use Text::CSV_XS qw( csv );

my $locations = location_for_geoname_id();

my $blocks_file = 'GeoLite2-City-Blocks-IPv4.csv';
my $blocks_csv = Text::CSV_XS->new( { binary => 1 } );
open my $fh, "<:encoding(utf8)", $blocks_file or die "$blocks_file: $!";

# https://metacpan.org/pod/Text::CSV_XS#getline_hr says that binding columns
# in this way makes for faster iterations.
my @cols = @{ $blocks_csv->getline( $fh ) };
my $row  = {};
$blocks_csv->bind_columns( \@{$row}{@cols} );

# We can match up blocks and locations based on geoname_id.  We'll just print
# a few rows here and leave the rest as an exercise for the reader.

my $count = 1;
while ( $blocks_csv->getline( $fh ) ) {
    say np( $row );
    say np( $locations->{ $row->{geoname_id} } );
    last if $count == 5;
    $count++;
}
close $fh;

# The locations CSV is small, so we'll just slurp it into memory.  For fast
# lookups, we'll return a HashRef which is keyed on geoname_id.

sub location_for_geoname_id {
    my $locations
        = csv( in => 'GeoLite2-City-Locations-en.csv', headers => 'auto' );
    my %by_geoname_id;
    for my $location ( @{$locations} ) {
        $by_geoname_id{ $location->{geoname_id} } = $location;
    }
    return \%by_geoname_id;
}
