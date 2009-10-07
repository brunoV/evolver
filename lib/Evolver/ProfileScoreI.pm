package Evolver::ProfileScoreI;
use Moose::Role;
use MooseX::Types::Moose qw(CodeRef Num);
use namespace::autoclean;

# Interface for Profile Score calculating engines.

# They should provide the _profile_score function, which takes a string
# and returns a score that describes some sort of similarity with the
# profile.

# In adittion, they should provide a maximum and minimum boundry for that
# score (ie., builders for _min_score and _max_score attributes) for proper
# normalization (0 to 1).

has _my_fitness => (
   is         => 'ro',
   lazy_build => 1,
   isa        => CodeRef,
);

has _min_score => (
   is         => 'ro',
   isa        => Num,
   lazy_build => 1,
);

has _max_score => (
   is         => 'ro',
   isa        => Num,
   lazy_build => 1,
);

sub _build__my_fitness {
   my $self = shift;

   return sub {
      my $string       = shift;
      my $string_score = $self->_profile_score($string);
      my $score        = ( $string_score - $self->_min_score )
          / ( $self->_max_score - $self->_min_score );
#      if ( $score < 0 ) { $score = 0 }
      return $score;
   };
}

1;
