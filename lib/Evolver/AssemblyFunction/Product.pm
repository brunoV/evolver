package Evolver::AssemblyFunction::Product;
use Moose;
use MooseX::Types::Moose qw(Num);
use namespace::autoclean;

with 'Evolver::AssemblyFunctionI';

has [qw(profile custom)] => ( is => 'ro', isa => Num, default => 1 );

sub evaluate {
    my ($self, $profile_score, $custom_score) = @_;

    die "profile score and/or custom score not provided"
        if not ( defined $profile_score and defined $custom_score );

    my ($p, $c) = ($self->profile, $self->custom);

    return ( $profile_score ** $p ) * ( $custom_score ** $c );
}

__PACKAGE__->meta->make_immutable;
