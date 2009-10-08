package Evolver::ProfileScore::Needleman;
use Moose::Role;
requires '_build__profile_score';
with 'Evolver::RandomSeq';

use Evolver::Types qw(Aligner);
use MooseX::Types::Moose qw(ArrayRef);
use Evolver::Aligner;
use namespace::autoclean;

## _min_score

sub _build__min_score {
   my $self = shift;
   my @rand_seq = split '', $self->_random_seq;
   return $self->_aligner->align(\@rand_seq, $self->_consensus_array);
}

## _max_score

has _consensus_array => (
   is  => 'ro',
   isa => ArrayRef,
   lazy_build => 1,
);

sub _build__consensus_array {
   my $self = shift;
   my @res = split '', $self->profile->consensus_string;
   return \@res;
}

sub _build__max_score {
   my $self = shift;
   return $self->_aligner->align(
      $self->_consensus_array,
      $self->_consensus_array
   );
}

## _score

has _aligner => (
   is  => 'ro',
   isa => Aligner,
   lazy_build => 1,
);

sub _build__aligner {
   my $self = shift;
   return Evolver::Aligner->new;
}

sub _score {
   my ($self, $string) = @_;
   my @string = split '', $string;
   return $self->_aligner->align(\@string, $self->_consensus_array);
}

1;
