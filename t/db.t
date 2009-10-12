use Test::More;
use Test::Exception;
use Evolver;
#use File::Temp;
use_ok( 'Evolver::DB' );

my $e = Evolver->new(
    profile => 't/seqs-test.fasta',
    fitness => sub { 1 },
    fitness_name => 'prueba',
    population_size => 5,
);

$e->evolve(1);

# my $tmpfile = File::Temp->new->filename;
my $tmpfile = 't/db';
my $db = Evolver::DB->connect("dbi:SQLite:dbname=$tmpfile");

isa_ok($db, 'Evolver::DB');

# Inserting Fitness
my $fitness_rs = $db->insert_function($e);

isa_ok($fitness_rs, 'Evolver::DB::Fitness');

# Inserting ProfileSeq
my $profile_seqs = $db->insert_profile_seqs($e);

isa_ok( $_, 'Evolver::DB::ProfileSeq' ) for @$profile_seqs;
is( scalar @profile_seqs, scalar @{$e->profile->each_seq} );

my $run = $db->insert_evolver($e);

done_testing();
