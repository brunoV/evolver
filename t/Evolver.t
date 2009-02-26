use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Test::Warn;
use Bio::AlignIO;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);
use Devel::SimpleTrace;

# TODO Test Roles independently, ok? Otherwise it's going to be one
# big-ass test file.

my @align_files = glob('t/profile-test.*');
my $align_file = $align_files[0];
my @seqs_files = glob('t/seqs-test.*');
my $seqs_file  = $seqs_files[0];

use_ok('Bio::Tools::Evolver');
can_ok(
   'Bio::Tools::Evolver',
   qw(terminate population crossover mutation parents selection
       strategy cache history preserve throw
       evolve chart getFittest getHistory getAvgFitness
       generation inject)
);

# Test constructor and passing different profile types to
# the profile attribute.
my $ev;

# 1.  Passing filenames.
# 1.1 Alignment files.
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $_,
      fitness => sub { return 1 },
   ) for @align_files;
}
'Profile: alignment files';
isa_ok( $ev, 'Bio::Tools::Evolver', "Constructor" );
isa_ok( $ev->profile, 'Bio::SimpleAlign' );

# 1.2 Sequence files.
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $seqs_file,
      fitness => sub { return 1 },
   );
} 'Profile: sequence files';

# 2. Passing an AlignIO object.
my $alignI = Bio::AlignIO->new( -file => "<$align_file" );
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $alignI,
      fitness => sub { return 1 },
   );
}
'Profile: AlignIO object';

# 3. Passing a SimpleAlign object.
$alignI = Bio::AlignIO->new( -file => "<$align_file" );
my $aln = $alignI->next_aln;
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $aln,
      fitness => sub { return 1 },
   );
}
'Profile: SimpleAlign object';

# 4. Passing a SeqIO object.
my $seqI = Bio::SeqIO->new( -file => $seqs_file );
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile => $seqI,
      fitness => sub { return 1 },
   );
}
'Profile: SeqIO object';

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
}
'Profile: Seq object';

# 6. Passing inexistent or empty files
throws_ok { 
   $ev = Bio::Tools::Evolver->new(
      profile => 'inexistent-file',
      fitness => sub { return 1 },
   );
} 'Bio::Root::Exception', 'Profile: inexistent file';

throws_ok { 
   $ev = Bio::Tools::Evolver->new(
      profile => 't/bogus-seq.bogus',
      fitness => sub { return 1 },
   );
} 'Bio::Root::Exception', 'Profile: empty file';

# Check for default values.
is( $ev->population, 300,  'default population' );
is( $ev->crossover,  0.95, 'default crossover' );
is( $ev->mutation,   0.01, 'default mutation rate' );
is( $ev->parents,    2,    'default parents' );
is_deeply( $ev->selection, ['Roulette'], 'default selection' );
is_deeply( $ev->strategy, [ 'Points', 2 ], 'default strategy' );
is( $ev->cache,           1, 'default cache' );
is( $ev->history,         1, 'default history' );
is( $ev->preserve,        5, 'default preserve' );
is( $ev->profile_algorithm, 'Simple', 'default profile algorithm' );

throws_ok { $ev->throw('Test error message') } 'Bio::Root::Exception', 'Throw';

# Initialize an object assigning attributes in the declaration.
undef $ev;
lives_ok {
   $ev = Bio::Tools::Evolver->new(
      profile         => $align_file,
      fitness         => sub { return 1 },
      population      => 1000,
      crossover       => 0.9,
      mutation        => 0.05,
      parents         => 3,
      selection       => ['RouletteBasic'],
      strategy        => [ 'Points', 5 ],
      cache           => '0',
      history         => 0,
      preserve        => 7,
      terminate       => sub { return 5 },
      profile_algorithm => 'Clustalw',
   );
}
'Initialization with non-default attributes';

is( $ev->population, 1000, 'changed population' );
is( $ev->crossover,  0.9,  'changed crossover' );
is( $ev->mutation,   0.05, 'changed mutation' );
is( $ev->parents,    3,    'changed parents' );
is_deeply( $ev->selection, ['RouletteBasic'], 'changed selection' );
is_deeply( $ev->strategy, [ 'Points', 5 ], 'changed strategy' );
is( $ev->cache,           0, 'changed cache' );
is( $ev->history,         0, 'changed history' );
is( $ev->preserve,        7, 'changed preserve' );

#SKIP : {
#   skip "Clustalw plugin doesn't work yet";
   $ev = Bio::Tools::Evolver->new(
      profile    => $align_file,
      population => 5,
      fitness    => \&count_hydroph,
      preserve   => 1,
      cache      => 0,
      profile_algorithm => 'Clustalw',
   );
   lives_ok { $ev->evolve(1) } 'Short evolution run: Clustalw';
#}
$ev = Bio::Tools::Evolver->new(
   profile    => $seqs_file,
   population => 2,
   fitness    => sub { 1 },
   preserve   => 0,
   cache      => 1,
   profile_algorithm => 'Needleman',
);
lives_ok { $ev->evolve(1) } 'Short evolution run: Needleman';

$ev = Bio::Tools::Evolver->new(
   profile    => $seqs_file,
   population => 5,
   fitness    => \&count_hydroph,
   preserve   => 1,
   cache      => 0,
);

lives_ok { $ev->evolve(1) } 'Short evolution run: Simple';

my @fittest = $ev->getFittest( 2, 1 );
is( scalar @fittest, 2, 'getFittest with arguments' );
isa_ok( $fittest[0], 'Bio::Seq' );

my $fittest = $ev->getFittest;
isa_ok( $fittest, 'Bio::Seq' );

# Testing injection.
$ev = Bio::Tools::Evolver->new(
   profile    => $align_file,
   population => 5,
   fitness    => sub { return 1 },
   cache      => 1,
);
$alignI = Bio::AlignIO->new( -file => "<$align_file" );
my ($string) = $alignI->next_aln->consensus_string;

my $seq = Bio::Seq->new( -seq => $string, -id => 'cons' ); my $short_seq = Bio::Seq->new(
   -seq => 'PNYVIKPWLEP',
   -id  => 'shorty',
);

dies_ok { $ev->inject('madre santa') } 'Injecting rubbish';
dies_ok {
   $ev->inject($short_seq)
} 'Injecting sequences with wrong length';
warning_like { $ev->inject() } qr/No arguments/i, 'Injecting nothing';

$ev->evolve(1);
lives_ok { $ev->inject($seq) } 'Injecting after evolving';

($fittest) = $ev->getFittest;
is( $fittest->seq, $string, 'Injection occured correctly' );

# Doing it the other way around (inject->evolve)
$ev = Bio::Tools::Evolver->new(
   profile => $align_file,
   population => 1,
   preserve => 1,
   fitness => sub { shift eq $seq and return 1000; return 0 },
);

lives_ok { $ev->inject($seq) } 'Injecting before evolving';
lives_ok { $ev->evolve(1)    } 'Evolving after injecting';
($fittest) = $ev->getFittest;
is( $fittest->seq, $string, 'Injection occured correctly' );

# Test terminate function
$ev = Bio::Tools::Evolver->new(
   profile => $align_file,
   population => 5,
   fitness => sub { return 1 },
   terminate => \&_has_F,
);

sub _has_F {
   my $seq = shift;
   my @res = (split '', $seq);
   return 1 if grep { $_ eq 'F' } @res;
   return 0;
}
$ev->inject($seq);
$ev->evolve();
is( $ev->generation, 0, 'Terminate function worked' );

#($fittest) = $ev->getFittest;

# TODO Write *the* test: a protein actually evolves.

# ok( count_hydroph($fittest) > count_hydroph($seqs[0]->seq) );
## ok( count_hydroph($fittest) > count_hydroph($seqs[1]->seq) );
#my $history = $ev->getHistory;
#$ev->chart(-width => 1042, -height => 768, -filename => 'evolution.png');
#print $ev->as_value($ev->_ga->getFittest), "<--\n";
#print $fittest->seq, "\n";
#print "fittest: ", count_hydroph($fittest->seq), "\n";
#print $seqs[1]->seq, "\n";
#print "normal: ", count_hydroph($seqs[1]->seq), "\n";

sub count_hydroph {
   my $string = shift;
   my $count = scalar grep { $_ =~ /[VALI]/ } split '', $string;
   return ( $count / length $string );
}
