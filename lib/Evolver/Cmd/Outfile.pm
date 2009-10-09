package Evolver::Cmd::Outfile;
use Moose::Role;
use MooseX::Getopt;
use namespace::autoclean;

use MooseX::Types::Moose qw(Str);
use Evolver::Types qw(BioSeqIO);

has outfile => (
    is  => 'ro',
    isa => Str,
    traits   => [qw(Getopt)],
    default  => 'outfile.fasta',
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
    my ($seq, $score) = ($seq_ref->{seq}, $seq_ref->{score});

    my $seq_obj = Bio::Seq->new(-id => $score, -seq => $seq);

    $self->seqO->write_seq($seq_obj);
}

1;
__END__
