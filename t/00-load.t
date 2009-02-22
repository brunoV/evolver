#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bio::Tools::Evolver' );
}

diag( "Testing Bio::Tools::Evolver $Bio::Tools::Evolver::VERSION, Perl $], $^X" );
