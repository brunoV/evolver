use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;

use_ok('Bio::Tools::Evolver');
can_ok(
   'Bio::Tools::Evolver',
   qw(terminate population crossover mutation parents selection
       strategy cache history preserve variable_length throw)
);

my $ev = Bio::Tools::Evolver->new;
isa_ok( $ev, 'Bio::Tools::Evolver' );

# Check for default values.
is($ev->population, 300);
is($ev->crossover, 0.95);
is($ev->mutation, 0.01);
is($ev->parents, 2);
is_deeply($ev->selection, ['Roulette']);
is_deeply($ev->strategy, ['Points', 2]);
is($ev->cache, 1);
is($ev->history, 1);
is($ev->preserve, 5);
is($ev->variable_length, 0);

# Check for correct delegation.
$ev->population(1000);
$ev->crossover(0.9);
$ev->mutation(0.05);
$ev->parents(3);
$ev->selection(['RouletteBasic']);
$ev->strategy(['Points', 5]);
$ev->cache(0);
$ev->history(1);
$ev->preserve(5);
$ev->variable_length(1);
$ev->terminate( sub { return 5 } );

is($ev->population, 1000);
is($ev->crossover, 0.9);
is($ev->mutation, 0.05);
is($ev->parents, 3);
is_deeply($ev->selection, ['RouletteBasic']);
is_deeply($ev->strategy, ['Points', 5]);
is($ev->cache, 0);
is($ev->history, 1);
is($ev->preserve, 5);
is($ev->variable_length, 1);
is($ev->terminate->(), 5);
dies_ok { $ev->throw('Test error message') };

# Users cannot access non-delegated methods
dies_ok { $ev->fitness( sub { return 5 } ) };

# But I can... (muahaha)
lives_ok { $ev->_ga->fitness( sub { return 5 } ) };
is( $ev->_ga->fitness->(), 5 );


