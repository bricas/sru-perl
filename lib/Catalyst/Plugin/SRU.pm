package Catalyst::Plugin::SRU;

use base qw( Class::Data::Inheritable );

use strict;

use SRU::Request;
use SRU::Response;
use SRU::Response::Diagnostic;
use CQL::Parser;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata( 'sru_request' );
__PACKAGE__->mk_classdata( 'sru_response' );
__PACKAGE__->mk_classdata( 'cql' );

=head1 NAME

Catalyst::Plugin::SRU - Dispatch SRU methods with Catalyst

=head1 SYNOPSIS

    # include it in plugin list
    use Catalyst qw( SRU );
	
    # Public action to redispatch
    sub sru : Global {
        my ( $self, $c ) = @_;
        $c->parse_sru;
    }
	
    # explain, scan and searchretrieve methods
    sub explain : Private {
        my ( $self, $c ) = @_;

	# $c->sru_request ISA SRU::Request::Explain
	# $c->sru_response ISA SRU::Response::Explain
    }
	
    sub scan : Private {
        my ( $self, $c ) = @_;

	# $c->cql ISA CQL::Parser root node
	# $c->sru_request ISA SRU::Request::Scan
	# $c->sru_response ISA SRU::Response::Scan
    }
	
    sub searchretrieve : Private {
        my ( $self, $c ) = @_;

	# $c->cql ISA CQL::Parser root node
	# $c->sru_request ISA SRU::Request::SearchRetrieve
	# $c->sru_response ISA SRU::Response::SearchRetrieve
    }

=head1 DESCRIPTION

This plugin allows your controller class to dispatch SRU actions
(C<explain>, C<scan>, and C<searchRetrieve>) from its own class.

=head1 METHODS

=head2 parse_sru( )

This method will create C<sru_response>, C<sru_request> (and possibly C<cql>) methods based on
the type of SRU request it finds. It will then pass the request over to your customized method.

=cut

sub parse_sru {
	my $c   = shift;
	my $sru = SRU::Request->newFromURI( $c->req->uri );

	$c->sru_request( $sru );
	$c->sru_response( SRU::Response->newFromRequest( $c->sru_request ) );

	my $cql;
	my $mode = lc( ( split( '::', ref $sru ) )[ -1 ] );
	if ( $mode eq 'scan' ) {
		$cql = $sru->scanClause;
	}
	elsif ( $mode eq 'searchretrieve' ) {
		$cql = $sru->query;
	}

	if( defined $cql ) {
		eval { $c->cql( CQL::Parser->new->parse( $cql ) ); };
		if ( $@ ) {
			$c->sru_response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( 10 ) );
		}
	}

	my $class = caller( 0 );
	if ( my $code = $class->can( $mode ) ) {
		$c->execute( $class, $code );
	}
	else {
		$c->log->debug( qq/Couldn't find sru method "$mode"/ ) if $c->debug;
	}

	$c->_serialize_response;
	return 0;
}

sub _serialize_response {
	my $c = shift;

	$c->res->content_type( 'text/xml' );
	$c->res->body( $c->sru_response->asXML );
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst>

=back

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;