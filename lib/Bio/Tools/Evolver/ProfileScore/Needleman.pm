package Bio::Tools::Evolver::ProfileScore;
use strict;
use warnings;
use Moose::Role;

use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::AlignIO;
use Bio::Tools::Evolver::Aligner;


use List::Util qw(shuffle);

use Data::Dumper;

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

   my $aligner = Bio::Tools::Evolver::Aligner->new; 
   my @cons_seq = split '', $self->profile->consensus_string;
   my @rand_seq = split '', $self->_random_seq;

   # Given a string, calculate the "family belongness score".
   my $max_score = $aligner->align(\@cons_seq, \@cons_seq); 
   my $min_score = $aligner->align(\@rand_seq, \@cons_seq);

   return sub {
      my @string = split '', shift;
      my $string_score 
         = $aligner->align(\@string, \@cons_seq);
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

no Moose;
1;
