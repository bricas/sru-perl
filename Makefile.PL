use inc::Module::Install 0.68;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/SRU.pm > README' );
}

name 'SRU';
all_from 'lib/SRU.pm';

requires 'XML::LibXML';
requires 'XML::Simple';
requires 'URI';
requires 'Class::Accessor';
requires 'CQL::Parser' => '0.3';

test_requires 'Test::More';
test_requires 'Test::Exception';

auto_install;
WriteAll;
