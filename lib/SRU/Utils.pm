package SRU::Utils;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( error );

sub error {
    if ( $_[0] ) { $SRU::Error = $_[0]; };
    return;
}

1;
