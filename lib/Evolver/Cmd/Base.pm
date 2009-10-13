package Evolver::Cmd::Base;

BEGIN { local $@; eval "use Time::HiRes qw(time)" };

use Moose;
use namespace::autoclean;
use MooseX::Types::Moose qw(Num CodeRef);

extends qw(MooseX::App::Cmd::Command);

with qw(
    MooseX::SimpleConfig
    Evolver::Cmd::DB
    Evolver::Cmd::Chart
    Evolver::Cmd::Silent
    Evolver::Cmd::Infile
    Evolver::Cmd::Outfile
    Evolver::Cmd::ScoreStats
);

has '+configfile' => (
    documentation => 'Configuration file',
);


has generations => (
    is  => 'ro',
    isa => Num,
    required => 1,
    traits   => [qw(Getopt)],
    cmd_aliases   => 'n',
    documentation => 'Number of generations to run (required)',
);

has evolver => (
    is  => 'ro',
    isa => 'Evolver',
    traits     => [qw(NoGetopt)],
    lazy_build => 1,
    handles    => [qw(history fittest generation chart)],
);

sub run {
    my ( $self, $opts, $args ) = @_;

    my $t  = -time();
    my $tc = -times;

    $self->e("Evolving...\n");

    for (1 .. $self->generations) {

        $self->evolve_once;

        $self->pf("%.3f\t%i\n",
            $self->fittest->{score}->{total}, $self->generation
        );
    }

    $self->e("Done.\n");

    $t  += time();
    $tc += times;

    $self->e(sprintf "completed in %.2fs (%.2fs cpu)\n", $t, $tc);

}

sub evolve_once {
    # I don't use delegation here, to be able to get method modifiers
    # on evolve for stuff that has to be done by the roles after each
    # evolution step

    my $self = shift;
    $self->evolver->evolve(1);
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 NAME

Evolver::Cmd::Base - Base class for writing L<Evolver> command line tools.

=head1 SYNOPSIS

    package Evolver::Cmd::Command::Blort;
    use Moose;

    extends qw(Evolver::Cmd::Base);

    augment run => sub {
        ...
    };

=head1 DESCRIPTION

This class provides shared functionality for L<Evolver> command line tools.
