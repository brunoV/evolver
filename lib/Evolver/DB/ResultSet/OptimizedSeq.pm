package Evolver::DB::ResultSet::OptimizedSeq;
use base 'Evolver::DB::ResultSet';

sub top { return shift->top_n(1) }

sub top_n {
    my ($self, $n) = @_;

    # Return the top N sequences, ordered by total_score

    $n || die "I need a number of top sequences\n";

    return $self->search(
        {},
        { order_by => { -desc => 'total_score' }, page => 1, rows => $n }
    );
}

sub top_10 {
    my $self = shift;

    $self->top_n(10);
}

1;
