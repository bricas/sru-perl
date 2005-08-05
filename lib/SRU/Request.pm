package SRU::Request;

use strict;
use warnings;
use URI;
use SRU::Request::Explain;
use SRU::Request::SearchRetrieve;
use SRU::Request::Scan;
use SRU::Utils qw( error );
use SRU::Utils::XML qw( escape );

=head1 NAME

SRU::Request - Factories for creating SRU request objects. 

=head1 SYNOPSIS

    use SRU::Request;
    my $request = SRU::Request->newFromURI( $uri );

=head1 DESCRIPTION

SRU::Request allows you to create the appropriate SRU request object
from a URI object. This allows you to pass in a URI and get back 
one of SRU::Request::Explain, SRU::Request::Scan or 
SRU::Request::SearchRetrieve depending on the type of URI that is passed 
in. See the docs for those classes for more information about what
they contain.

=head1 METHODS

=head2 newFromURI()

newFromURI() is a factory method which you pass a complete SRU url. 
newFromURI() will return an appropriate object for the type of request being 
conducted:

=over 4

=item * SRU::Request::Explain

=item * SRU::Request::Scan

=item * SRU::Request::SearchRetrieve

=back

If the request is not formatted properly the call will return undef. 
The error encountered should be available in $SRU::Error.

=cut

sub newFromURI {
    my ($class,$uri) = @_;

    ## be nice and try to turn a string into a URI if necessary
    if ( ! UNIVERSAL::isa( $uri, 'URI' ) ) { $uri = URI->new($uri); }
    return error( "invalid uri: $uri" ) if ! UNIVERSAL::isa( $uri, 'URI' ); 

    my %query     = $uri->query_form();
    my $operation = $query{operation} || 'explain';

    my $request;
    if ( $operation eq 'scan' ) { 
        $request = SRU::Request::Scan->new( %query );
    } elsif ( $operation eq 'searchRetrieve' ) {
        $request = SRU::Request::SearchRetrieve->new( %query );
    } elsif ( $operation eq 'explain' ) {
        $request = SRU::Request::Explain->new( %query );
    } else {
        $request = SRU::Request::Explain->new( %query );
        $request->missingOperator(1);
    }

    return $request;
}

=head2 newFromCGI()

A factory method for creating a request object from a CGI object.

    my $cgi = CGI->new();
    my $request = SRU::Request->newFromCGI( $cgi );

=cut

sub newFromCGI {
    my ($class,$cgi) = @_;

    ## We want either an actual CGI object
    return error( "invalid CGI object" ) unless UNIVERSAL::isa( $cgi, 'CGI' );

    ## we must have ampersands between query string params, but lets
    ## make sure we don't screw anybody else up
    my $saved = $CGI::USE_PARAM_SEMICOLONS; 
    $CGI::USE_PARAM_SEMICOLONS = 0;
    my $url = $cgi->self_url();
    $CGI::USE_PARAM_SEMICOLONS = $saved;

    return $class->newFromURI( $url );
}

=head2 asXML()

Used to generate <echoedExplainRequest>, <echoedSearchRetrieveRequest> and
<echoedScanRequest> elements in the response.

=cut

sub asXML {
    my $self = shift;

    ## extract the type of request from the type of object
    my ($type) = ref($self) =~ /^SRU::Request::(.*)$/;
    $type = "echoed${type}Request";

    ## build the xml
    my $xml = "<$type>";

    ## add xml for each param if it is available
    foreach my $param ( $self->validParams() ) {
        $xml .= "<$param>" . escape($self->$param) . "</$param>" 
            if $self->$param;
    }
    ## add XCQL if appropriate
    if ( $self->can( 'cql' ) ) {
        my $cql = $self->cql();
        if ( $cql ) {
            my $xcql = $cql->toXCQL(0);
            chomp( $xcql );
            $xcql =~ s/>\n *</></g; # collapse whitespace
            $xml .= "<xQuery>$xcql</xQuery>";
        }
    }

    $xml .= "</$type>";
    return $xml;
}

1;
