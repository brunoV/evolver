use Test::More;

use_ok( 'Evolver' );

my $e = Evolver->new(
    fitness => sub { 1 },
    profile => 't/profile-test.phy',
    population_size => 5
);

$e->evolve(3);

foreach my $score (qw(custom profile total)) {
    my $history = 'history_' . $score;
    is( ref $e->$history, 'HASH' );
    ok( defined $e->$history->{$_} )      for qw(min max mean);
    is( ref $e->$history->{$_}, 'ARRAY' ) for qw(min max mean);
    is( scalar @{$e->history->{$_}}, 3  ) for qw(min max mean);
}

done_testing;
