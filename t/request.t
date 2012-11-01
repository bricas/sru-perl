use strict;
use warnings;

use Test::More;
use SRU::Request;

my @urls = (
'http://myserver.com/myurl?operation=scan&version=1.1&scanClause=%2fdc.title%3d%22cat%22&responsePosition=3&maximumTerms=50&stylesheet=http://myserver.com/myStyle',
'http://myserver.com/myurl?operation=explain&version=1.0&recordPacking=xml&stylesheet=http://www.example.com/style.xsl&extraRequestData=123',
'http://myserver.com/myurl?operation=searchRetrieve&version=1.1&query=dc.identifier+%3d%220-8212-1623-6%22&recordSchema=dc&recordPacking=XML&stylesheet=http://myserver.com/myStyle',
);

sub normalize_url {
    my $url = URI->new(shift);
    my %query = $url->query_form;
    my @sorted = map { $_ => $query{$_} } sort keys %query;
    $url->query_form( \@sorted, '&' );
    return $url;
}

sub is_same_url {
    is normalize_url($_[0]), normalize_url($_[1]), $_[2];
}

foreach my $url (@urls) {
    my $uri = URI->new( $url );
    my $request = SRU::Request->newFromURI( $uri );

    my $base = "http://myserver.com/myurl";
    is_same_url( $request->asURI($base), $uri, 'asURI with base');

    $uri->host('localhost');
    $uri->path('/');
    is_same_url( $request->asURI, $uri, 'asURI without base');
}

done_testing;
