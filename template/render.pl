#!/usr/bin/env perl;

use strict;
use warnings;
use feature qw( say );

use Path::Tiny;
use Text::Xslate;

my $tx = Text::Xslate->new(
    path   => [ 'template', 'examples' ],
    syntax => 'TTerse'
);

path( 'blog-post.md' )->spew( $tx->render( 'blog-post.md' ) );

