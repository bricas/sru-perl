package SRU::Utils::XMLTest;

use strict;
use warnings;
use XML::LibXML;
use base qw( Exporter );

our @EXPORT = qw( wellFormedXML );

sub wellFormedXML {
    my $xml_string = shift;
    eval {  
        my $parser = XML::LibXML->new;
        $parser->parse_string($xml_string);
    };
    return $@ ? 0 : 1;
}

1;
