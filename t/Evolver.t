use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Bio::AlignIO;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);

my $align_file = 't/profile-test.gcg';
my $seqs_file  = 't/seqs-test.fasta';

use_ok('Bio::Tools::Evolver');
can_ok(
   'Bio::Tools::Evolver',
   qw(terminate population crossover mutation parents selection
       strategy cache history preserve variable_length throw
       evolve chart getFittest)
);

# Test constructor and passing different profile types to
# the profile attribute.
my $ev;

# 1. Passing an alignment file.
lives_ok { 
   $ev = Bio::Tools::Evolver->new(
      profile => $align_file,
      fitness => sub {},
   ) 
};
isa_ok( $ev, 'Bio::Tools::Evolver', "Constructor" );
is( $ev->profile, 't/profile-test.gcg' );

# 2. Passing an AlignIO object.
my $alignI = Bio::AlignIO->new( -file => "<$align_file" );
lives_ok { 
   $ev = Bio::Tools::Evolver->new( 
      profile => $alignI,
      fitness => sub {},
   )
};

# 3. Passing a SimpleAlign object.
$alignI = Bio::AlignIO->new( -file => "<$align_file" );
my $aln = $alignI->next_aln;
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $aln,
      fitness => sub {},
   )
};

# 4. Passing a SeqIO object.
my $seqI = Bio::SeqIO->new( -file => $seqs_file );
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $seqI,
      fitness => sub {}
   )
};

# 5. Passing an arrayref of Bio::Seq objects.
$seqI = Bio::SeqIO->new( -file => $seqs_file );
my @seqs;
while ( my $seq = $seqI->next_seq ) { push @seqs, $seq };
ok( @seqs > 1 );
isa_ok( $seqs[1], 'Bio::Seq');
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => [@seqs],
      fitness => sub {},
   )
};

# Check for default values.
is( $ev->population, 300 );
is( $ev->crossover,  0.95 );
is( $ev->mutation,   0.01 );
is( $ev->parents,    2 );
is_deeply( $ev->selection, ['Roulette'] );
is_deeply( $ev->strategy, [ 'Points', 2 ] );
is( $ev->cache,           1 );
is( $ev->history,         1 );
is( $ev->preserve,        5 );
is( $ev->variable_length, 0 );

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

is( $ev->population, 1000 );
is( $ev->crossover,  0.9 );
is( $ev->mutation,   0.05 );
is( $ev->parents,    3 );
is_deeply( $ev->selection, ['RouletteBasic'] );
is_deeply( $ev->strategy, [ 'Points', 5 ] );
is( $ev->cache,           0 );
is( $ev->history,         1 );
is( $ev->preserve,        5 );
is( $ev->variable_length, 1 );
is( $ev->terminate->(),   5 );
dies_ok { $ev->throw('Test error message') };

# Users cannot access non-delegated methods
dies_ok {
   $ev->fitness( sub { return 5 } );
};

# But I can... (muahaha)
lives_ok {
   $ev->_ga->fitness( sub { return 5 } );
};
is( $ev->_ga->fitness->(), 5 );
