package SRU::Utils::XMLTest;

use strict;
use warnings;
use XML::LibXML;
use base qw( Exporter );

our @EXPORT = qw( wellFormedXML );

=head1 NAME

SRU::Utils::XMLTest - XML testing utility functions

=head1 SYNOPSIS

    use SRU::Utils::XMLText;
    ok( wellFormedXML($xml), '$xml is well formed' );

=head1 DESCRIPTION

This is a set of utility functions for use with testing XML data.

=head1 METHODS

=head2 wellFormedXML( $xml )

Checks if C<$xml> is welformed.

=cut

sub wellFormedXML {
    my $xml_string = shift;
    eval {  
        my $parser = XML::LibXML->new;
        $parser->parse_string($xml_string);
    };
    return $@ ? 0 : 1;
}

1;
