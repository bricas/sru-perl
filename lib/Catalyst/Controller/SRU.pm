package Catalyst::Controller::SRU;

use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

Catalyst::Controller::SRU - Dispatch SRU methods with Catalyst

=head1 SYNOPSIS

    package MyApp::Controller::SRU;

    # use it as a base controller
    use base qw( Catalyst::Controller::SRU );
        
    # explain, scan and searchretrieve methods
    sub explain {
        my ( $self, $c,
            $sru_request, # ISA SRU::Request::Explain
            $sru_resuest, # ISA SRU::Response::Explain 
        ) = @_;
    }
    
    sub scan {
        my ( $self, $c,
            $sru_request, # ISA SRU::Request::Scan
            $sru_resuest, # ISA SRU::Response::Scan
            $cql,         # ISA CQL::Parser root node
        ) = @_;

    }
    
    sub searchRetrieve {
        my ( $self, $c,
            $sru_request, # ISA SRU::Request::SearchRetrieve
            $sru_resuest, # ISA SRU::Response::SearchRetrieve
            $cql,         # ISA CQL::Parser root node
        ) = @_;
    }

=head1 DESCRIPTION

This module allows your controller class to dispatch SRU actions
(C<explain>, C<scan>, and C<searchRetrieve>) from its own class.

=head1 METHODS

=head2 index : Private

This method will create an SRU request, response and possibly a CQL object methods based on
the type of SRU request it finds. It will then pass the data over to your customized method.

=cut

use base qw( Catalyst::Controller );

use SRU::Request;
use SRU::Response;
use SRU::Response::Diagnostic;
use CQL::Parser;

my @cql_errors = (
    { regex => qr/does not support relational modifiers/,   code => 20 },
    { regex => qr/expected boolean got /,                   code => 37 },
    { regex => qr/expected relation modifier got /,         code => 20 },
    { regex => qr/unknown first-class relation modifier: /, code => 20 },
    { regex => qr/missing term/,                            code => 27 },
    { regex => qr/expected proximity relation got /,        code => 40 },
    { regex => qr/expected proximity distance got /,        code => 41 },
    { regex => qr/expected proximity unit got/,             code => 42 },
    { regex => qr/expected proximity ordering got /,        code => 43 },
    { regex => qr/unknown first class relation: /,          code => 19 },
    { regex => qr/must supply name/,                        code => 15 },
    { regex => qr/must supply identifier/,                  code => 15 },
    { regex => qr/must supply subtree/,                     code => 15 },
    { regex => qr/must supply term parameter/,              code => 27 },
    { regex => qr/doesn\'t support relations other than/,   code => 20 },
);

sub index : Private {
    my( $self, $c ) = @_;

    my $sru_request  = SRU::Request->newFromURI( $c->req->uri );
    my $sru_response = SRU::Response->newFromRequest( $sru_request );
    my @args         = ( $sru_request, $sru_response );

    my $cql;
    my $mode = $sru_request->type;
    if ( $mode eq 'scan' ) {
        $cql = $sru_request->scanClause;
    }
    elsif ( $mode eq 'searchRetrieve' ) {
        $cql = $sru_request->query;
    }

    if( defined $cql ) {
        push @args, eval { CQL::Parser->new->parse( $cql ) };
        if ( my $error = $@ ) {
            my $code = 10;
            for( @cql_errors ) {
                $code =  $_->{ code } if $error =~ $_->{ regex };
            }
            $sru_response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( $code ) );
        }
    }

    if ( my $action = $self->can( $mode ) ) {
        $action->( $self, $c, @args );
    }
    else {
        $sru_response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( 4 ) );
        $c->log->debug( qq(Couldn't find sru method "$mode") ) if $c->debug;
    }

    $c->res->content_type( 'text/xml' );
    $c->res->body( $sru_response->asXML );
};

=head1 SEE ALSO

=over 4

=item * L<Catalyst>

=back

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
