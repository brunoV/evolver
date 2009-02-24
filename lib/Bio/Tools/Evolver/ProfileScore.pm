package Bio::Tools::Evolver::ProfileScore;
use strict;
use warnings;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Bio::Tools::Evolver::Types;

use List::MoreUtils qw(each_array);

has 'matrix' => (
   is      => 'ro',
   isa     => 'BTE::Bio::Matrix::Scoring',
   coerce  => 1,
   default => 'BLOSUM62',
);

sub _calculate_lowest_score {
   my $self = shift;
   my $matrix = $self->matrix;
   my @rows = $matrix->row_names;
   my @cols = $matrix->column_names;
   my $min = 0;
   foreach my $row (@rows) {
      foreach my $col (@cols) {
         $min = $matrix->get_entry($row, $col) < $min ?
                $matrix->get_entry($row, $col) : $min;
      }
   }
   $self->matrix->lowest_score($min);
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
   if (!$self->matrix->lowest_score) { $self->_calculate_lowest_score };
   my $min_score = $self->matrix->lowest_score * length $consensus;

   return sub {
      my $string = shift;
      my $string_score 
         = $self->_score_f_absolute( $string,  $consensus );
      my $score = ( ( $string_score - $min_score ) / ( $max_score - $min_score ) );
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
