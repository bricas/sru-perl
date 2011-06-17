package SRU::Client;

use 5.006;

use XML::Simple;
use SRU::Request;
use SRU::Response;
use LWP::Simple;
use Moose;

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

our $VERSION = '0.02';

has url => (
	is	=> 'rw',
	isa	=> 'Str',	# define a URL type???
	required	=> 1,
);

has query => (
	is	=> 'rw',
	isa	=> 'Str',
	required	=> 1,
);

has recordSchema => (
	is	=> 'rw',
	isa	=> 'Str',
	# funny, the spec defaults of Dublin Core if not specified but I need LOM
	#error#		validate	=> sub { defined $_ && $_ =~ /^(?:lom|dc)$/ },
);

has operation => (
	is	=> 'rw',
	isa	=> 'Str',	# limited types, warn on setting other value
	default	=> 'searchRetrieve',
);

has version => (
	is	=> 'rw',
	isa	=> 'Str',
	default	=> '1.1',
);

has numberOfRecords => (
	is	=> 'rw',
	isa	=> 'Int',
);

has startRecord => (
	is	=> 'rw',
	isa	=> 'Int',
	lazy	=> 1,
	default	=> 0,
);

has recordPosition => (
	is	=> 'rw',
	isa	=> 'Int',
	lazy	=> 1,
	default	=> 0,
	trigger	=> \&_set_next_starting_position,
);

sub _set_next_starting_position {
	my ($self, $last_record_fetched, $previous) = @_;

	$self->startRecord($last_record_fetched + 1);	# start at the next record
}

sub _make_request {
	my $self = shift;

	# could've cycled through all the keys in the object hash
	my $indulgence = join '&', map { join '=', $_, $self->$_ } 
					grep { $self->$_ }
					qw(operation version recordSchema query startRecord);
	my $req = join '?', $self->url, $indulgence;
	return get($req);
}

sub request {
	my $self = shift;

	my $response = SRU::Response::SearchRetrieve->new( SRU::Request::SearchRetrieve->new() )
		or die "Couldn't make SRU::Response object: $!\n";

	my $simple = XML::Simple->new();
	my $tree = $simple->XMLin( $self->_make_request() )
		or die "Couldn't get $self->url: $!\n";

	return undef unless $tree->{'SRW:records'};		# no records  - use Confess??

	my $last_record_position = 0;
	foreach my $r (  ref $tree->{'SRW:records'}->{'SRW:record'} eq 'ARRAY' 
						? @{$tree->{'SRW:records'}->{'SRW:record'}}
						: $tree->{'SRW:records'}->{'SRW:record'}  ) {
		# Multiple records are stored in an array, but one record is given directly to you
		# If you're having to maintain this, I sincerely apologize.

		my $record = SRU::Response::Record->new(
                               recordSchema    => $self->recordSchema,
                               recordData      => $r->{'SRW:recordData'},
                        );
		$response->addRecord( $record );

		$last_record_position = $r->{'SRW:recordPosition'};
	}

	$self->numberOfRecords( $tree->{'SRW:numberOfRecords'} );
	$self->recordPosition( $last_record_position );

	return $response;
}

sub get_records {
	# assume that we're getting a SRU::Response::SearchRetrieve object
	my $self = shift;

	return $self->records();
}

__PACKAGE__->meta->make_immutable;

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

Here, have an example:

$client = SRU::Client->new( {
                        url => 'http://repository.keele.ac.uk:8080/intralibrary/IntraLibrary-SRU',
                        query => 'rec.collectionIdentifier=6a6176612e7574696c2e52616e646f6d40326630663837',
                        recordSchema => 'lom',
            		} );
while( $request = $client->request() ) {
	$records_ref = $request->records() or warn $request->diagnostics();

    foreach ( @{$records_ref} ) {
        $lom_ref = $_->{'recordData'}->{'lom:lom'}->{'lom:general'};
		foreach my $k ( @{$lom_ref->{'lom:keyword'}} ) {
                push @keywords, $k->{'lom:string'}->{content};
        }
	}
}

print "Keywords: ", join ", ", @keywords;


=head2 METHODS

Use B<new> to create a SRU::Client object and set the parameters in the
constructor or by using the B<url> and B<query> methods.

The B<request> method returns a SRU::Response object with a schema of LOM
and the recordData holding the XML response at the SRW:recordData level.
Repeated calls to request fetch more pages until it returns undef.

There is a B<get_records> method to return all the records (naturally), but
I've never used it.

Because we're using Moose, there are getter and setter methods for all of the
attributes: B<
url
query
recordSchema
operation
version
numberOfRecords
startRecord
recordPosition
>.  I've set B<startRecord> to fast-forward through the results.


=head1 SEE ALSO

SRU::Response

SRU::Request

http://www.loc.gov/standards/sru

=head1 TODO

add the following optional request parameters:
recordPacking
resultSetTTL
stylesheet
extraRequestData


=head1 AUTHOR

Boyd Duffee, E<lt>duffee at cpan dot org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Boyd Duffee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
