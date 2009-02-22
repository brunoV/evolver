package Bio::Tools::Evolver::ProfileScore;
use strict;
use warnings;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);
use Moose::Role;
use Moose::Util::TypeConstraints;

use Bio::Matrix::IO;
use Bio::Tools::Evolver::Types;

use File::Basename;
use List::MoreUtils qw(each_array);

has 'matrix' => (
   is      => 'ro',
   isa     => 'BTE.Bio.Matrix.Scoring',
   coerce  => 1,
   default => 'BLOSUM62',
);

coerce 'BTE.Bio.Matrix.Scoring'
   => from 'BTE.MatrixFile' => via { _parse_matrixfile( $_[0] ) }
   => from 'BTE.Bio.Matrix.IO' =>  via { return $_[0]->next_matrix }
   => from 'BTE.MatrixName'  => via { _parse_matrixfile( _get_path( $_[0] ) ) };

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

has _my_fitness => (
   is         => 'ro',
   lazy_build => 1,
   isa        => 'CodeRef',
);

sub _build__my_fitness {
   my $self = shift;

   my $consensus = $self->profile->consensus_string;
   # Given a string, calculate the "family belongness score".
   my $max_score = $self->_score_f_absolute( $consensus,
      $consensus );
   my $min_score = -4 * length $consensus;

   return sub {
      my $string = shift;
      my $string_score 
         = $self->_score_f_absolute( $string,  $consensus );
      my $score = ( ( $string_score - $min_score ) / ( $max_score - $min_score ) );
      if ($score < 0) { $score = 0 };
      return $score;
   };
}

sub _score_f_absolute {

   # Given a string, calculate the alignment score against the given
   # profile.
   my ( $self, $seq_string, $cons_string ) = @_;
   my $score;
   my @seq_res = split '', $seq_string;
   my @cons_res = split '', $cons_string;

   my $pair = each_array( @seq_res, @cons_res );
   while ( my ($seq, $cons) = $pair->() ) {
      $score += $self->matrix->get_entry($seq, $cons);
   }
   return $score;
}

no Moose;
1;
