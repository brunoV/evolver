package Bio::Tools::Evolver::Aligner;
use Moose;

use Bio::Tools::Evolver::Types qw(
    AlgorithmNeedlemanWunsch BioMatrixScoring
);

use Algorithm::NeedlemanWunsch;
use Memoize;
use namespace::autoclean;

has '_aligner' => (
   is         => 'ro',
   isa        => AlgorithmNeedlemanWunsch,
   lazy_build => 1,
   handles    => [qw(align)],
);

sub _build__aligner {
   my $self      = shift;
   my $gap_penalty = $self->score_for( '*', 'A' );
   my $score_sub = sub {
      if ( !@_ ) { return $gap_penalty } # gap penalty
      return $self->score_for( $_[0], $_[1] );
   };
   memoize($score_sub);
   my $aligner = Algorithm::NeedlemanWunsch->new($score_sub);
   return $aligner;
}

has 'matrix' => (
   is      => 'ro',
   isa     => BioMatrixScoring,
   coerce  => 1,
   default => 'BLOSUM62',
   handles => { score_for => 'get_entry' },
);

__PACKAGE__->meta->make_immutable;
