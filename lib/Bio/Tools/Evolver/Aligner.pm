package Bio::Tools::Evolver::Aligner;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib/);
use Moose;
use Moose::Util::TypeConstraints;

use Bio::Matrix::IO;
use Bio::Tools::Evolver::Types;

use Algorithm::NeedlemanWunsch;
use File::Basename;
use Memoize;

has '_aligner' => (
   is         => 'ro',
   isa        => 'BTE.Algorithm.NeedlemanWunsch',
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
   isa     => 'BTE.Bio.Matrix.Scoring',
   coerce  => 1,
   default => 'BLOSUM62',
   handles => { score_for => 'get_entry' },
);

coerce 'BTE.Bio.Matrix.Scoring' 
   => from 'BTE.MatrixFile'    => via { _parse_matrixfile( $_[0] ) }
   => from 'BTE.Bio.Matrix.IO' => via { return $_[0]->next_matrix }
   => from 'BTE.MatrixName'    => via { _parse_matrixfile( _get_path( $_[0] ) ) };

sub _parse_matrixfile {
   my $file = shift;
   my $parser = Bio::Matrix::IO->new( -file => $file )
       or die "Couldn't open scoring matrix $file : $!";
   return $parser->next_matrix;
}

sub _get_path {
   my $matrix_name = shift;
   my $full_path = __FILE__;
   my ($module_file, $directories, $suffix) = fileparse($full_path);
   if ($directories) { return $directories . $matrix_name };
   return $matrix_name;
}


no Moose;
__PACKAGE__->meta->make_immutable;
