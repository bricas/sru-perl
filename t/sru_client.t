# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SRU-Client.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { 
	# delete $ENV{HTTP_PROXY};	# uncomment this line if you fail the network connection test

	eval "use Moose;";
	eval "use LWP::Simple;";
	eval "use Carp;";

	plan skip_all => "install Moose, LWP::Simple and Carp if you want to use SRU::Client" if $@;

	plan tests => 15;
	use_ok('SRU::Client');
}

#########################

$my_url = 'http://repository.keele.ac.uk:8080/intralibrary/IntraLibrary-SRU';
$my_query = 'rec.collectionIdentifier=6a6176612e7574696c2e52616e646f6d40326630663837';

$client = SRU::Client->new(
			url => $my_url,
			query => $my_query,
			# recordSchema => 'lom', # should test a Dublin Core example sometime
		);
	
#?operation=searchRetrieve&version=1.1&recordSchema=lom&query=rec.collectionIdentifier=6a6176612e7574696c2e52616e646f6d40326630663837

#### check if HTTP_PROXY is obstructing the test
use LWP::Simple qw( get );
ok( get('http://www.google.co.uk'), 'Checking network connection (see documentation for BUGS)' );

isa_ok($client, 'SRU::Client', 'checking object class');

#### checking attributes are set correctly ####
is( $client->url(), $my_url, 'get/set url' );
is( $client->query(), $my_query, 'get/set query' );
$schema = $client->recordSchema();
ok( (!defined $schema) || $schema =~ m/^dc|lom$/, 'has valid recordSchema' );

# doesn't like these - use Test::Class instead???
#can_ok('SRU::Client', qw(request), 'checking class methods exist');
#can_ok( $client, qw(request), 'checking object methods exist');

#### check functionality ####
#$client->recordSchema('lom');	# this test needs LOM, I think
$response = $client->request();
isa_ok($response, 'SRU::Response::SearchRetrieve', 'checking class of response to request');

$numberOfRecords = $client->numberOfRecords();
$recordPosition = $client->recordPosition();
ok( $numberOfRecords > 0, 'how many records are there?' );
ok( $recordPosition > 0, 'what record are we at?' );
like( $numberOfRecords, qr/^\d+$/, 'numberOfRecords is an integer' );
like( $recordPosition, qr/^\d+$/, 'recordPosition is an integer' );

#### get next page ####
$response = $client->request();
$nextStartRecord = $client->startRecord();
ok( $nextStartRecord > 0, 'following page startRecord');
$nextRecordPosition = $client->recordPosition();
ok( $recordPosition < $numberOfRecords 			# must be more records to fetch
	&& $nextRecordPosition > $recordPosition	# must get more records
	&& $nextRecordPosition <= $numberOfRecords, # can't get more than there actually are, can we?
	'getting the next page of results' );

#### get single (last) result ####
$client->startRecord($numberOfRecords);
ok($client->request(), 'ONE single record and the xml changes - who thought of that!');


#### corner cases ####
$client->startRecord($numberOfRecords+1);
$response = $client->request();
ok( ! defined $response, "There shouldn't be more responses than records, n'est-ce pas?" );

done_testing();

#### For diagnostics ####
#
# print STDERR <<"OUTPUT";
# 
# =====
# request query
# startRecord of next request: $nextStartRecord
# number of records: $numberOfRecords
# record position: $recordPosition
# =====
# OUTPUT
#
####
