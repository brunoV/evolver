package Evolver::Cmd::Command::Hydroph;
use Moose;
use namespace::autoclean;

use Evolver;

extends qw(Evolver::Cmd::Base);

sub _build_evolver {
    my $self = shift;

    my $ev = Evolver->new(
        %{$self->_evolver_extra_init_args},
        profile      => $self->infile,
        fitness      => \&f,
        fitness_name => 'hydroph',
    );

    return $ev;
}

sub f {
    my $seq   = shift;
    my @count = grep { /H/ } (split '', $seq);

    return scalar @count;
}

__PACKAGE__->meta->make_immutable;
