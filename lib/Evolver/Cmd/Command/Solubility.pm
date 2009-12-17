package Evolver::Cmd::Command::Solubility;
use Moose;
use Bio::Tools::Solubility::Wilkinson solubility => { -as => 'f' };
use namespace::autoclean;

use Evolver;

extends qw(Evolver::Cmd::Base);

sub _build_evolver {
    my $self = shift;

    my $ev = Evolver->new(
        %{$self->_evolver_extra_init_args},
        profile      => $self->infile,
        fitness      => \&f,
        fitness_name => 'solubility',
    );

    return $ev;
}

__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

Evolver::Cmd::Command::Solubility - Increase the solubility probability using the Wilkinson method

=cut
