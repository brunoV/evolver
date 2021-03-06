package Evolver::Cmd::Command::Digestibility;
use Moose;

extends 'Evolver::Cmd::Base';

use namespace::autoclean;

use MooseX::Types::Moose qw(ArrayRef);
use Bio::Protease;

my @proteases;

sub BUILD {
    my $self = shift;

    my $tryp = Bio::Protease->new( specificity => 'trypsin'      );
    my $chym = Bio::Protease->new( specificity => 'chymotrypsin' );
    my $peps = Bio::Protease->new( specificity => 'pepsin'       );

    @proteases = ( $tryp, $chym, $peps );
}

sub _build_evolver {
    my $self = shift;

    my $ev = Evolver->new(
        %{$self->_evolver_extra_init_args},
        profile => $self->infile,
        fitness => \&f,
        fitness_name => 'digestibility',
    );

    return $ev;
}

sub f {
    my $seq = shift;

    my @sites;

    foreach my $protease ( @proteases ) {
        push @sites, $protease->cleavage_sites( $seq );
    }

    return @sites / length $seq;
}

__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

Evolver::Cmd::Command::Digestibility - Increase the digestibility

=cut
