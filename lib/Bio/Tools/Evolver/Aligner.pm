package Bio::Tools::Evolver::Aligner;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib/);
use Moose;
use Moose::Util::TypeConstraints;

use Bio::Tools::Evolver::Types;

use Algorithm::NeedlemanWunsch;
use Memoize;

has '_aligner' => (
   is         => 'ro',
   isa        => 'BTE::Algorithm::NeedlemanWunsch',
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
   isa     => 'BTE::Bio::Matrix::Scoring',
   coerce  => 1,
   default => 'BLOSUM62',
   handles => { score_for => 'get_entry' },
);

no Moose;
__PACKAGE__->meta->make_immutable;
