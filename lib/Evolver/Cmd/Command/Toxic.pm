package Evolver::Cmd::Command::Toxic;
use Moose;

extends 'Evolver::Cmd::Biopep';

use namespace::autoclean;

use MooseX::Types::Path::Class qw(File);

has '+activity' => ( default => 'toxic' );

# Since we want to *reduce* the presence of toxic peptides,
# the return value of the function has to be modified

sub _build_evolver {
    my $self = shift;

    my $ev = Evolver->new(
        profile => $self->infile,
        fitness => \&f_modified,
    );

    return $ev;
}

sub f_modified {
    my $seq = shift;

    # Annotate the sequence using the in-memory database.
    my $seq_obj = Evolver::Cmd::Biopep::annotate_seq(\$seq);

    # Count all the useful peptides (this is a naïve approach).
    my $biopep_count = Evolver::Cmd::Biopep::get_encrypted_biopeps($seq_obj);

    return ( 1 - $biopep_count / length $seq );
}

__PACKAGE__->meta->make_immutable;
