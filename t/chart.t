use Test::More;
use Test::Exception;
use File::Temp;
use Evolver;
use autodie;

my $e = Evolver->new(
    profile => 't/seqs-test.fasta',
    population_size => 5,
    fitness => sub { 1 }
);

$e->evolve(2);

my $tmpfile = File::Temp->new->filename;

lives_ok { $e->chart(output => $tmpfile . '.eps') };

ok( -e $tmpfile . '.eps' );

unlink $tmpfile . '.eps';

done_testing;
