package SRU::Utils;
#ABSTRACT: Utility functions for SRU

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( error );

=head1 SYNOPSIS

    use SRU::Utils qw( error );
    return error( "error!" );

=head1 DESCRIPTION

This is a set of utility functions for the SRU objects.

=head1 METHODS

=head2 error( $message )

Sets the C<$SRU::Error> message.

=cut

sub error {
    if ( $_[0] ) { $SRU::Error = $_[0]; };
    return;
}

1;
