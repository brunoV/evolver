package Bio::Tools::Evolver::RandomSeq;
use Moose::Role;
use MooseX::Types::Moose qw(Str);
use List::Util qw(shuffle);
use namespace::autoclean;

has _random_seq => (
   is         => 'ro',
   lazy_build => 1,
   isa        => Str,
);

sub _build__random_seq {
   my $self       = shift;
   my $random_seq = _shuffle_string(
      'ACDEFGHIKLMNPQRSTVWY' x int( $self->profile->length / 20 ) );
   return $random_seq;
}

sub _shuffle_string {
   my $string = shift;
   my @elms = split '', $string;
   return join( '', shuffle @elms );
}

1;
