use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

my @align_files = glob('t/profile-test.*');
my $align_file = $align_files[0];
my @seqs_files = glob('t/seqs-test.*');
my $seqs_file  = $seqs_files[0];

use_ok('Evolver');
can_ok(
   'Evolver',
   qw(terminate population_size crossover mutation parents selection
       strategy cache history preserve evolve chart fittest
       current_stats current_population generation)
);

my $ev = Evolver->new(
   profile => $seqs_file,
   fitness => sub {1},
);

# Check for default values.
is( $ev->population_size, 300,  'default population' );
is( $ev->crossover,  0.95, 'default crossover' );
is( $ev->mutation,   0.05, 'default mutation rate' );
is( $ev->parents,    2,    'default parents' );
is_deeply( $ev->selection, ['Roulette'], 'default selection' );
is_deeply( $ev->strategy, [ 'Points', 2 ], 'default strategy' );
is( $ev->cache,           1, 'default cache' );
is( $ev->preserve,        5, 'default preserve' );
is( $ev->profile_algorithm, 'Hmmer', 'default profile algorithm' );
is( $ev->inject_consensus, 1, 'default inject_consensus' );

# Initialize an object assigning attributes in the declaration.
undef $ev;
lives_ok {
   $ev = Evolver->new(
      profile           => $seqs_file,
      fitness           => sub { return 1 },
      population_size   => 10,
      crossover         => 0.9,
      mutation          => 0.01,
      parents           => 3,
      selection         => ['RouletteBasic'],
      strategy          => [ 'Points', 5 ],
      cache             => '0',
      preserve          => 7,
      terminate         => sub { return 5 },
      profile_algorithm => 'Simple',
      inject_consensus  => 0,
   );
}
'Initialization with non-default attributes';

is( $ev->population_size, 10,   'changed population' );
is( $ev->crossover,       0.9,  'changed crossover'  );
is( $ev->mutation,        0.01, 'changed mutation'   );
is( $ev->parents,         3,    'changed parents'    );
is_deeply( $ev->selection, ['RouletteBasic'], 'changed selection' );
is_deeply( $ev->strategy, [ 'Points', 5 ], 'changed strategy' );
is( $ev->cache,             0,        'changed cache'             );
is( $ev->preserve,          7,        'changed preserve'          );
is( $ev->profile_algorithm, 'Simple', 'changed profile_algorithm' );
is( $ev->inject_consensus,  0,        'changed inject_consensus'  );

done_testing();
