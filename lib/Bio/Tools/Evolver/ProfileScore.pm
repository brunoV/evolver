package Bio::Tools::Evolver::ProfileScore;
use strict;
use warnings;
use Moose::Role;

use Bio::Tools::Run::Alignment::Clustalw;
use Bio::AlignIO;

use List::Util qw(shuffle);
use Memoize;
memoize('_score_f_absolute');

has _random_seq => (
   is         => 'ro',
   lazy_build => 1,
   isa        => 'Str',
);

sub _build__random_seq {
   my $self       = shift;
   my $random_seq = _shuffle_string(
      'ACDEFGHIKLMNPQRSTVWY' x int( $self->profile->length / 20 ) );
   return $random_seq;
}

has _my_fitness => (
   is         => 'ro',
   lazy_build => 1,
   isa        => 'CodeRef',
);

sub _build__my_fitness {
   my $self = shift;

   my $factory = Bio::Tools::Run::Alignment::Clustalw->new( quiet => 1 );

   # Given a string, calculate the "family belongness score".
   my $max_score = _score_f_absolute( $self->profile->consensus_string,
      $self->profile, $factory );
   my $min_score = _score_f_absolute( $self->_random_seq, $self->profile,
      $factory );

   my $prof_file = $self->profile;

   return sub {
      my $string = shift;
      my $string_score 
         = _score_f_absolute( $string, $prof_file, $factory );
      my $score = ( ( $string_score - $min_score ) / ( $max_score - $min_score ) );
      if ($score < 0) { $score = 0 };
      return $score;
   };
}

sub _shuffle_string {
   my $string = shift;
   my @elms = split '', $string;
   return join( '', shuffle @elms );
}

sub _score_f_absolute {

   # Given a string, calculate the alignment score against the given
   # profile.
   my ( $seq_string, $prof_file, $factory ) = @_;
   my $alignment = $factory->profile_align(
      $prof_file,
      Bio::Seq->new(
         -id  => 'x',
         -seq => $seq_string,
      )
   );
   return $alignment->score;
}

no Moose;
1;
