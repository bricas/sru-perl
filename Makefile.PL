use ExtUtils::MakeMaker;
use strict;
use warnings;

## create the Makefile
WriteMakefile(
    'NAME'		=> 'SRU',
    'DISTNAME'		=> 'SRU',
    'ABSTRACT'		=> 'Search and Retrieve URL Service',
    'VERSION_FROM'	=> 'lib/SRU.pm', 
    'PMLIBDIRS'		=> [ qw( lib/ ) ],
    'AUTHOR'		=> 'Ed Summers <ehs@pobox.com>',
    'PREREQ_PM'		=> { 
                            'XML::LibXML'       => '',
                            'XML::Simple'       => '',
                            'URI'               => '',
                            'Class::Accessor'   => '',
                            'CGI::Application'  => '',
                            'CQL::Parser'       => '0.3',
                            'Test::Exception'   => '',
			   },
);
