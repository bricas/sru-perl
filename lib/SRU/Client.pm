package SRU::Client;

use 5.010000;
use strict;
use warnings;

#use XML::DOM;
use XML::Simple;
use SRU::Request;
use SRU::Response;
use LWP::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SRU::Client ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
			url 	=> $arg_ref->{'url'} || undef,
			query	=> $arg_ref->{query} || undef,
			recordSchema 	=> 'lom',
			operation 	=> 'searchRetrieve',
			version => '1.1',
		};
	bless $self, $class;

	return $self;
}

sub query {
	my $self = shift;
	if (@_) { $self->{'query'} = shift; }

	return $self->{'query'};
}

sub url {
	my $self = shift;
	if (@_) { $self->{'url'} = shift; }

	return $self->{'url'};
}

sub _make_request {
	my $self = shift;

	# could've cycled through all the keys in the object hash
	my $indulgence = join '&', map { join '=', $_, $self->{$_} } 
					qw(operation version recordSchema query);
	my $req = join '?', $self->{url}, $indulgence;
	return get($req);
}

sub request {
	my $self = shift;

	my $response = SRU::Response::SearchRetrieve->new( SRU::Request::SearchRetrieve->new() )
		or die "Couldn't make SRU::Response object: $!\n";

	my $simple = XML::Simple->new();
	my $tree = $simple->XMLin( $self->_make_request() )
		or die "Couldn't get $self->{url}: $!\n";

	foreach my $r (  @{$tree->{'SRW:records'}->{'SRW:record'}}  ) {
		# this could get fussy when dealing with either one or many records

		my $record = SRU::Response::Record->new(
                               recordSchema    => 'lom',
                               recordData      => $r->{'SRW:recordData'},
                        );
		$response->addRecord( $record );

	}

	return $response;
}

sub get_records {
	# assume that we're getting a SRU::Response::SearchRetrieve object
	my $self = shift;

	return $self->records();
}

1;
__END__

=head1 NAME

SRU::Client - Perl extension for SRU goodness

=head1 SYNOPSIS

  use SRU::Client;

It's fragile as all get out.

=head1 DESCRIPTION

Blah blah blah.

(Shhhh!  Daddy's in a hurry)

I've been using it to take LOM records and strip out the keyword fields
with XML::Simple

=head2 METHODS

Use B<new> to create a SRU::Client object and set the parameters in the
constructor or by using the B<url> and B<query> methods.

The B<request> method returns a SRU::Response object with a schema of LOM
and the recordData holding the XML response at the SRW:recordData level.


=head1 SEE ALSO

SRU::Response

SRU::Request

=head1 TODO

Go through Damian's OO Perl book and redo getter/setter methods
Or even better, use Moose (but that means _another_ module dependancy)

Some tests

=head1 AUTHOR

Boyd Duffee, E<lt>duffee at cpan dot org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Boyd Duffee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
