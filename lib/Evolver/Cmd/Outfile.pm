package Evolver::Cmd::Outfile;
use Moose::Role;
use MooseX::Getopt;
use namespace::autoclean;

use MooseX::Types::Moose qw(Str);
use Evolver::Types qw(BioSeqIO);

has outfile => (
    is  => 'ro',
    isa => Str,
    traits        => [qw(Getopt)],
    predicate     => 'has_outfile',
    cmd_aliases   => 'o',
    documentation => 'Filename to which to output the fittest sequence of each generation',
);

has seqO => (
    is  => 'ro',
    isa => BioSeqIO,
    traits     => [qw(NoGetopt)],
    lazy_build => 1,
);

sub _build_seqO {
    my $self = shift;

    my $seqO = Bio::SeqIO->new(
        -file   => ">" . $self->outfile,
        -format => 'fasta',
    );

    return $seqO;
}

sub write {
    my ($self, $seq_ref) = @_;
    return unless $self->has_outfile;

    my ($seq, $score) = ($seq_ref->{seq}, $seq_ref->{score});

    my $id = sprintf(
        "Total: %2.4f Custom: %2.4f", $score->{total}, $score->{custom}
    );

    my $seq_obj = Bio::Seq->new(-id => $id, -seq => $seq);

    $self->seqO->write_seq($seq_obj);
}

after evolve_once => sub {
    my $self = shift;

    $self->write( $self->fittest );
};

1;
__END__
