use strict;
use warnings;
use Test::More tests => 8; 
use CGI;

## flag to CGI::Application so that run() returns output
## rather than printing it.
$ENV{ CGI_APP_RETURN_ONLY } = 1;

INHERITANCE: {
    my $app = MyApp->new();
    isa_ok( $app, 'MyApp' );
    isa_ok( $app, 'CGI::Application' );
}

DEFAULT_RESPONSE: {
    my $app = MyApp->new();
    $app->query( CGI->new() );
    my $content = $app->run();
    like( $content, qr|^Content-Type: text/xml|, 'content-type' );
    like( $content, qr|<foo>bar</foo>|, 'contains record' );
    like( $app->run(), qr/<explainResponse/, 'got default explain response' );
}

EXPLAIN: {
    my $app = MyApp->new();
    $app->query( CGI->new( 'operation=explain' ) );
    like( $app->run(), qr/<explainResponse/, 'got explain response' );
}

SCAN: {
    my $app = MyApp->new();
    $app->query( CGI->new( 'operation=scan&version=1' ) );
    like( $app->run(), qr/<scanResponse/, 'got scan response' );
}

SEARCH_RETRIEVE: {
    my $app = MyApp->new();
    $app->query( CGI->new( 'operation=searchRetrieve&version=1' ) );
    like( $app->run(), qr/<searchRetrieveResponse/,    
        'got searchRetrieve response' );
}

############################
## a harmless SRU::Server subclass 

package MyApp;

use base qw( SRU::Server );

sub explain {
    my $self = shift;
    my $response = $self->response();
    $response->record( 
        SRU::Response::Record->new(
            recordSchema => 'http://explain.z3950.org/dtd/2.0/',
            recordData   => '<foo>bar</foo>'
        )
    );
}

sub searchRetrieve {
}

sub scan {
}

1;

