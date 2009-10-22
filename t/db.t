use strict;
use warnings;
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

$e->evolve(2);

my $tmpfile = File::Temp->new->filename;

my $db;

Basic: {

    lives_ok {
        $db = Evolver::DB->connect("dbi:SQLite:dbname=$tmpfile");
        $db->deploy;
    } 'Lived through database connection and deployment';

    isa_ok($db, 'Evolver::DB');

}

Inserting: {
# Inserting Fitness
    my $fitness_rs = $db->insert_function($e);

    isa_ok($fitness_rs, 'Evolver::DB::Result::Fitness');

    my $run = $db->insert_evolver($e);

    isa_ok($run, 'Evolver::DB::Result::Run');

    my @optimized_seqs = $db->optimized_seqs($e, 2);

    is( @optimized_seqs, 2 );
    is( ref $optimized_seqs[0], 'HASH' );
    ok( defined $optimized_seqs[0]->{$_} ) for qw(seq custom_score total_score generation);

    my $optimized_seq_rs = $db->add_optimized_seq_to_run($run, $optimized_seqs[0]);

    isa_ok( $optimized_seq_rs, 'Evolver::DB::Result::OptimizedSeq' );
}

View: {

    my $view = $db->resultset('Result');

    isa_ok( $view,        'DBIx::Class::ResultSet'           );
    isa_ok( $view->first, 'Evolver::DB::Result::Result'      );
}

ResultSet: {

    my @rss = ($db->resultset('OptimizedSeq'), $db->resultset('Result'));

    foreach my $rs (@rss) {
        can_ok( $rs, qw(top_n top top_10) );

        dies_ok { $rs->top_n(undef) } 'top_n without arg dies';

        my @top = $rs->top_n(1);

        is( @top, 1, 'top_n(1) returns one sequence' );
    }
}

unlink $tmpfile;
done_testing();
