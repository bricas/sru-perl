package SRU::Server;

=head1 NAME 

SRU::Server - respond to SRU requests via CGI::Application

=head1 SYNOPSIS

    package MySRU;

    use base qw( SRU::Server );

    sub explain {
        my $self = shift;

        # $self->request isa SRU::Request::Explain
        # $self->response isa SRU::Response::Explain
    }

    sub scan {
        my $self = shift;

        # $self->request isa SRU::Request::Scan
        # $self->response isa SRU::Response::Scan
        # $self->cql is the root node of a CQL::Parser-parsed query
    }

    sub searchRetrieve {
        my $self = shift;

        # $self->request isa SRU::Request::SearchRetrieve
        # $self->response isa SRU::Response::SearchRetrieve
        # $self->cql is the root node of a CQL::Parser-parsed query
    }

    package main;

    MySRU->new->run;

=head1 DESCRIPTION

This module brings together all of the SRU verbs (explain, scan
and searchRetrieve) under a sub-classable object based on CGI::Application.

=cut

=head1 METHODS

=head2 explain

This method is used to return an explain response. It is the default
method.

=head2 scan

This method returns a scan response.

=head2 searchRetrieve

This method returns a searchRetrieve response.

=cut

use base qw( CGI::Application Class::Accessor );

use strict;
use warnings;

use SRU::Request;
use SRU::Response;
use SRU::Response::Diagnostic;
use CQL::Parser;

use constant ERROR   => -1;
use constant DEFAULT => 0;

my @modes     = qw( explain scan searchRetrieve error_mode );
my @accessors = qw( request response cql );

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

__PACKAGE__->mk_accessors( @accessors );

=head1 CGI::APPLICATION METHODS

=head2 setup

Sets the C<run_modes>, C<mode_param> and the default runmode (explain).

=cut

sub setup {
    my $self = shift;

    $self->run_modes( \@modes );
    $self->start_mode( $modes[ DEFAULT ] );
    $self->mode_param( 'operation' );
}

=head2 cgiapp_prerun

Parses the incoming SRU request and if needed, checks the CQL query.

=cut

sub cgiapp_prerun {
    my $self = shift;
    my $mode = shift;

    $CGI::USE_PARAM_SEMICOLONS = 0;

    $self->request( SRU::Request->newFromURI( $self->query->url( -query => 1 ) ) );
    $self->response( SRU::Response->newFromRequest( $self->request ) );

    my $cql;
    if ( $mode eq 'scan' ) {
        $cql = $self->request->scanClause;
    }
    elsif ( $mode eq 'searchRetrieve' ) {
        $cql = $self->request->query;
    }

    if( defined $cql ) {
        eval {
            $self->cql( CQL::Parser->new->parse( $cql ) );
        };
        if ( my $error = $@ ) {
            $self->prerun_mode( $modes[ ERROR ] );
            my $code = 10;
            for( @cql_errors ) {
                $code =  $_->{ code } if $error =~ $_->{ regex };
            }
            $self->response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( $code ) );
        }
    }

    unless( $self->can( $mode ) ) {
            $self->prerun_mode( $modes[ ERROR ] );
            $self->response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( 4 ) );
    }
}

=head2 cgiapp_postrun

Sets the content type (text/xml) and serializes the response.

=cut

sub cgiapp_postrun {
    my $self       = shift;
    my $output_ref = shift;

    $self->header_add( -type => 'text/xml' );

    $$output_ref = $self->response->asXML;
}

=head2 error_mode

Stub error runmode.

=cut

sub error_mode {
}

=head1 AUTHORS

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=item * Ed Summers E<lt>ehs@pobox.comE<gt>

=back

=cut

1;
