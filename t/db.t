use Test::More;
use Test::Exception;
use Evolver;
use autodie;
use File::Temp;

use_ok( 'Evolver::DB' );

my $e = Evolver->new(
    profile => 't/seqs-test.fasta',
    fitness => sub { 1 },
    fitness_name => 'prueba',
    population_size => 5,
);

$e->evolve(1);

my $tmpfile = File::Temp->new->filename;
my $db = Evolver::DB->connect("dbi:SQLite:dbname=$tmpfile");
$db->deploy;

isa_ok($db, 'Evolver::DB');

# Inserting Fitness
my $fitness_rs = $db->insert_function($e);

isa_ok($fitness_rs, 'Evolver::DB::Fitness');

my $run = $db->insert_evolver($e);

isa_ok($run, 'Evolver::DB::Run');

my $optimized_seq_rs = $db->add_optimized_seqs_to_run($e, $run, 1);

isa_ok( $optimized_seq_rs, 'Evolver::DB::OptimizedSeq' );

unlink $tmpfile;
done_testing();
