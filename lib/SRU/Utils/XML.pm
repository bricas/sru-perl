package SRU::Utils::XML;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( element elementNoEscape escape stylesheet );

sub element {
    my ($tag,$text) = @_;
    return '' if ! defined $text;
    return "<$tag>" . escape($text) . "</$tag>";
}

sub elementNoEscape {
    my ($tag,$text) = @_;
    return '' if ! defined $text;
    return "<$tag>$text</$tag>";
}

sub escape {
    my $text = shift || '';
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/&/&amp;/g;
    return $text;
}

sub stylesheet {
    my $uri = shift;
    return qq(<?xml-stylesheet type='text/xsl' href="$uri" ?>);
}

1;
