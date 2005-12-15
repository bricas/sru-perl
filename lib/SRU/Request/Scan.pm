package SRU::Request::Scan;

use strict;
use warnings;
use base qw( Class::Accessor SRU::Request );
use UNIVERSAL qw( isa );
use SRU::Utils qw( error );

=head1 NAME

SRU::Request::Scan - A class for representing SRU scan requests

=head1 SYNOPSIS

    ## creating a new request
    my $request = SRU::Request::Scan->new();

=head1 DESCRIPTION

SRU::Request::Scan is a class for representing SRU 'scan' requests. 

=head1 METHODS

=head2 new()

The constructor, which you can pass the parameters: version, scanClause
responsePosition, maximumTerms, stylesheet, extraRequestData.

    my $request = SRU::Request::Explain->new( 
        version     => '1.1',
        scanClause  => 'horses',
    );

=cut

sub new {
    my ($class,%args) = @_;
    return $class->SUPER::new( \%args );
}

=head2 version()

=head2 scanClause()

=head2 responsePosition()

=head2 maximumTerms()

=head2 stylesheet()

=head2 extraRequestData()

=cut

my @validParams = qw( 
    version
    scanClause
    responsePosition
    maximumTerms
    stylesheet
    extraRequestData
);

=head2 validParams()

=cut

sub validParams { return @validParams; }

SRU::Request::Scan->mk_accessors( @validParams );

=head2 cql()

Fetch the root node of the CQL parse tree for the scan clause. 

=cut 

sub cql {
    my $self = shift;
    my $clause = $self->scanClause();
    return '' unless $clause;
    my $node;
    my $parser = CQL::Parser->new();
    eval { $node = $parser->parse( $clause ) };
    return $node;
}


1;
