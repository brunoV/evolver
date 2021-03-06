package Evolver::ProfileScore::Simple;
use Moose::Role;
requires '_build__profile_score';

use MooseX::Types::Moose qw(ArrayRef);
use Evolver::Types qw(BioMatrixScoring);
use List::MoreUtils qw(each_array);
use namespace::autoclean;

## _min_score

sub _build__min_score {
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
   # Ya que estoy, lleno el atributo de Bio::Matrix::Scoring;
   $self->matrix->lowest_score($min);
   return $min * length ($self->profile->consensus_string);
}

## _max_score

has _consensus_array => ( 
   is => 'ro',
   lazy_build => 1,
   isa => ArrayRef,
);

sub _build__consensus_array {
   my $self = shift;
   my @res = split '', $self->profile->consensus_string;
   return \@res;
}

sub _build__max_score {
   my $self = shift;
   return $self->_profile_score($self->profile->consensus_string);
}

## _score

has 'matrix' => (
   is      => 'ro',
   isa     => BioMatrixScoring,
   coerce  => 1,
   default => 'BLOSUM62',
);

sub _score {

   # Given a string, calculate the alignment score against the given
   # profile.
   my ( $self, $seq, ) = @_;
   my $score;
   my @seq_array = split '', $seq;

   my $pair = each_array( @seq_array, @{$self->_consensus_array} );
   while ( my ($seq, $cons) = $pair->() ) {
      $score += $self->matrix->get_entry($seq, $cons);
   }
   return $score;
}

1;
