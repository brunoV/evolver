use Test::More;

use_ok( 'Evolver' );

my $e = Evolver->new(
    fitness => sub { 1 },
    profile => 't/profile-test.phy',
    population_size => 5
);

$e->evolve(2);

foreach my $score (qw(custom profile total)) {
    my $history = 'history_' . $score;
    is( ref $e->$history, 'HASH' );
    ok( defined $e->$history->{$_} )      for qw(min max mean);
    is( ref $e->$history->{$_}, 'ARRAY' ) for qw(min max mean);
    is( scalar @{$e->history->{$_}}, 2  ) for qw(min max mean);
    cmp_ok( $e->$history ->{min}->[1], '<=', $e->$history->{mean}->[1] );
    cmp_ok( $e->$history->{mean}->[1], '<=', $e->$history ->{max}->[1] );
}

done_testing;
