package SRU::Request::Explain;

use strict;
use warnings;
use base qw( Class::Accessor SRU::Request );
use SRU::Utils qw( error );

=head1 NAME

SRU::Request::Explain - A class for representing SRU explain requests

=head1 SYNOPSIS

    ## creating a new request
    my $request = SRU::Request::Explain->new();

=head1 DESCRIPTION

SRU::Request::Explain is a class for representing SRU 'explain' requests. 
Explain requests essentially ask the server to describe its services.

=head1 METHODS

=head2 new()

The constructor, which you can pass the optional parameters parameters: 
version, recordPacking, stylesheet, and extraRequestData parameters.

    my $request = SRU::Request::Explain->new( 
        version     => '1.1',
        stylesheet  => 'http://www.example.com/styles/mystyle.xslt'
    );

Normally you'll probably want to use the factory SRU::Response::newFromURI
to create requests, instead of calling new() yourself.

=cut

sub new {
    my ($class,%args) = @_;
    return SRU::Request::Explain->SUPER::new( \%args );
}

=head2 version()

=head2 recordPacking()

=head2 stylesheet()

=head2 extraRequestData()

=cut

my @validParams = qw( 
    version 
    recordPacking 
    stylesheet 
    extraRequestData 
);

# no pod since this is used in SRU::Request
sub validParams { return @validParams };

SRU::Request::Explain->mk_accessors( @validParams, 'missingOperator' ); 

1;
