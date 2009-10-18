package Evolver::Cmd::Base;

BEGIN { local $@; eval "use Time::HiRes qw(time)" };

use Moose;
use namespace::autoclean;
use MooseX::Types::Moose qw(Num Str ArrayRef HashRef CodeRef);
use Modern::Perl;

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
    traits   => ['Getopt'],
    cmd_aliases   => 'n',
    documentation => 'Number of generations to run (required)',
);

has evolver => (
    is  => 'ro',
    isa => 'Evolver',
    traits     => ['NoGetopt'],
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

my @params = qw(mutation crossover strategy parents selection
             preserve population_size profile_algorithm
             inject_consensus inject_profile_seqs);

has $_ => (
    is => 'ro',
    isa => Num,
    traits    => ['Getopt'],
    predicate => 'has_' . $_,
) for qw(mutation crossover parents inject_consensus preserve population_size);

has $_ => (
    is  => 'ro',
    isa => ArrayRef,
    predicate => 'has_' . $_,
    traits    => ['Getopt'],
) for qw(strategy selection);

has 'profile_algorithm' => (
    is  => 'ro',
    isa => Str,
    traits    => ['Getopt'],
    predicate => 'has_profile_algorithm',
);

has _evolver_extra_init_args => (
    is  => 'ro',
    isa => HashRef,
    traits     => ['NoGetopt'],
    lazy_build => 1,
);

has inject_profile_seqs => (
    is      => 'ro',
    default => 1,
    traits  => ['Getopt'],
    documentation => 'Inject every sequence from the alignment',
);

sub _build__evolver_extra_init_args {
    my $self = shift;

    my @mod_attrs  = grep { my $a = 'has_' . $_; $self->$a } @params;
    my %extra_args = map  { my $m = $_; $m => $self->$m    } @mod_attrs;

    return \%extra_args;
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
