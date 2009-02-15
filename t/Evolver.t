use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Bio::AlignIO;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);

# TODO Test Roles independently, ok? Otherwise it's going to be one
# big-ass test file.

my $align_file = 't/profile-test.phy';
my $seqs_file  = 't/seqs-test.fasta';

use_ok('Bio::Tools::Evolver');
can_ok(
   'Bio::Tools::Evolver',
   qw(terminate population crossover mutation parents selection
       strategy cache history preserve variable_length throw
       evolve chart getFittest _profile_file _random_seq _fitness
       _build__fitness _shuffle_string _build__random_seq)
);

# Test constructor and passing different profile types to
# the profile attribute.
my $ev;

# 1. Passing an alignment file.
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $align_file,
      fitness => sub { return 1 },
   );
} 'Profile: alignment file';
isa_ok( $ev, 'Bio::Tools::Evolver', "Constructor" );
isa_ok( $ev->profile, 'Bio::SimpleAlign' );

# 2. Passing an AlignIO object.
my $alignI = Bio::AlignIO->new( -file => "<$align_file" );
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $alignI,
      fitness => sub { return 1 },
   );
} 'Profile: AlignIO object';

# 3. Passing a SimpleAlign object.
$alignI = Bio::AlignIO->new( -file => "<$align_file" );
my $aln = $alignI->next_aln;
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $aln,
      fitness => sub { return 1 },
   );
} 'Profile: SimpleAlign object';

# 4. Passing a SeqIO object.
my $seqI = Bio::SeqIO->new( -file => $seqs_file );
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $seqI,
      fitness => sub { return 1 }
   );
} 'Profile: SeqIO object';

# 5. Passing an arrayref of Bio::Seq objects.
$seqI = Bio::SeqIO->new( -file => $seqs_file );
my @seqs;
while ( my $seq = $seqI->next_seq ) { push @seqs, $seq }
ok( @seqs > 1, "File $seqs_file has more than one sequence" );
isa_ok( $seqs[1], 'Bio::Seq' );
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => [@seqs],
      fitness => sub { return 1 },
   );
} 'Profile: Seq object';

# Check for default values.
is( $ev->population, 300, 'default population' );
is( $ev->crossover,  0.95, 'default crossover' );
is( $ev->mutation,   0.01, 'default mutation rate' );
is( $ev->parents,    2, 'default parents' );
is_deeply( $ev->selection, ['Roulette'], 'default selection' );
is_deeply( $ev->strategy, [ 'Points', 2 ], 'default strategy' );
is( $ev->cache,           1, 'default cache' );
is( $ev->history,         1, 'default history' );
is( $ev->preserve,        5, 'default preserve' );
is( $ev->variable_length, 0, 'default variable_length' );

# Check for correct delegation.
$ev->population(1000);
$ev->crossover(0.9);
$ev->mutation(0.05);
$ev->parents(3);
$ev->selection( ['RouletteBasic'] );
$ev->strategy( [ 'Points', 5 ] );
$ev->cache(0);
$ev->history(1);
$ev->preserve(5);
$ev->variable_length(1);
$ev->terminate( sub { return 5 } );

is( $ev->population, 1000, 'changed population' );
is( $ev->crossover,  0.9, 'changed crossover' );
is( $ev->mutation,   0.05, 'changed mutation' );
is( $ev->parents,    3, 'changed parents' );
is_deeply( $ev->selection, ['RouletteBasic'], 'changed selection' );
is_deeply( $ev->strategy, [ 'Points', 5 ], 'changed strategy' );
is( $ev->cache,           0, 'changed cache' );
is( $ev->history,         1, 'changed history' );
is( $ev->preserve,        5, 'changed preserve' );
is( $ev->variable_length, 1, 'changed variable_length' );
is( $ev->terminate->(),   5, 'hitting terminate' );
dies_ok { $ev->throw('Test error message') } 'Throw';

# Users cannot access non-delegated methods
dies_ok {
   $ev->fitness( sub { return 5 } );
} 'fitness is ro';

# But I can... (muahaha)
lives_ok {
   $ev->_ga->fitness( sub { return 5 } );
} 'private fitness';
is( $ev->_ga->fitness->(), 5, "Set ga->fitness" );

# Testing Bio::Tools::Evolver::ProfileScore;
$ev = Bio::Tools::Evolver->new(
   profile => $align_file,
   fitness => sub { },
);
ok( $ev->_random_seq =~ m/^[ABCDEFGHIKLMNPQRSTVWXYZU]+$/, '_random_seq' );
my $code = $ev->_fitness;
isa_ok($code , 'CODE' );
my $score;
lives_ok { 
   $score = $code->('ABCDEFGHIKLMNPQRSTVWXYZU' x 25 ),
} '_fitness return function';
ok( $score =~ /^-?\d+[\.\d+]*$/, '_fitness returns a number' );
