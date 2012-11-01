package SRU::Client;

use 5.006;

use XML::Simple;
use SRU::Request;
use SRU::Response;
use LWP::Simple;
use Carp;
use Moose;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SRU::Client ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
# our %EXPORT_TAGS = ( 'all' => [ qw(
# ) ] );
#
# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( request get_records );

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
		or croak "Couldn't make SRU::Response object: $!\n";

	my $simple = XML::Simple->new();
	my $tree = $simple->XMLin( $self->_make_request() )
		or croak "Couldn't get $self->url: $!\n";

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

SRU::Client - Helps you create scripts that query SRU-capable repositories.

=head1 SYNOPSIS

  use SRU::Client;
  $client = SRU::Client->new( \%options );

=head1 DESCRIPTION

This module lets you create a client that queries a SRU repository and
returns the records that are returned.

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

Feel free to use the URL and query above.  They correspond with our Research Repository and
I'm trying to advertise the contents anyways.  Just be polite and don't DOS my server.

=head2 METHODS

=over

=item * B<new>

Use B<new> to create a SRU::Client object and set the parameters in the
constructor or by using the B<url> and B<query> methods.

=item * B<request>

The B<request> method returns a SRU::Response object with a schema of LOM
and the recordData holding the XML response at the SRW:recordData level.
Repeated calls to B<request> fetch more pages until it returns undef.

=item * B<get_records>

There is a B<get_records> method to return all the records (naturally), but
I've never used it.

=back

Because we're using Moose, there are getter and setter methods for all of the
attributes: B<
url,
query, 
recordSchema,
operation,
version,
numberOfRecords,
startRecord,
recordPosition,
>.  I've set B<startRecord> to fast-forward through the results.


=head1 SEE ALSO

=over

=item * SRU::Response

=item * SRU::Request

=item * L<http://www.loc.gov/standards/sru>

=back 

=head2 Discussion

Some of you may be new to SRU and are just using this module to get your job
done.  If I were an expert in SRU, here is where I'd put a nice discussion of
the differences between LOM and Dublin Core and the stuff you need to know
to get your job done and get on with life.  Until that time, I'd suggest
reading the Description in SRU.pm

The SRU::Client request cycle is in place to keep repositories over-committing
resources to a request that the client no longer needs.  The meaning is that
the client needs to repeat the B<request> call to fetch a new "page" of 
results for processing.  See the C<while> loop of the example.

I wrote this to fetch LOM records from intraLibrary L<http://www.intrallect.com>
and strip out the keyword fields with XML::Simple to present an auto-suggestion
php script for SRUOpenSearch L<http://code.google.com/p/sruopensearch>

=head1 TODO

=over 

=item * add the following optional request parameters:
recordPacking, resultSetTTL, stylesheet and extraRequestData

=item * improve the XML parsing of the return documents to make it more robust

=item * test with Dublin Core records

=item * improve diagnostics and set error messages in $SRU::Error

=item * add a discussion of SRU concepts for the beginner

=item * change the UserAgent string with $ua->agent('SRU::Client/$VERSION')

=back

=head1 BUGS

=head2 Dublin Core

I have no idea what happens with Dublin Core records.  Mea culpa.

=head2 HTTP_PROXY

If you've got HTTP_PROXY set on your machine, LWP::Simple's C<get> function may bomb.
Try unsetting the variable in the shell with C<unset HTTP_PROXY> or uncomment the
C<delete $ENV{HTTP_PROXY}> line in the BEGIN block of the test and run the tests again.  

If it passes the second time, you'll just have to add C<delete $ENV{HTTP_PROXY};>
to the BEGIN block of your script or remember to unset it in the shell before running 
the script uses SRU::Client.  This is caused by LWP::Simple calling B<< $ua->env_proxy >>
at compile time which picks up the proxy.  If you've got a better solution, I'd love
to hear it.

Please report problems to the Author.
Patches are welcome.

=head1 AUTHOR

Boyd Duffee, Keele University, E<lt>duffee at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Boyd Duffee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 (DISCLAIMER OF) WARRANTY

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
