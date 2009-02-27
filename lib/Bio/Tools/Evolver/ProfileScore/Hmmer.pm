package Bio::Tools::Evolver::ProfileScore::Hmmer;
use Moose::Role;
use Bio::Tools::Run::Hmmer;
use File::Temp;
use List::Util qw(shuffle);

has _random_seq => (
   is         => 'ro',
   lazy_build => 1,
   isa        => 'Str',
);

sub _build__random_seq {
   my $self       = shift;
   my $random_seq = _shuffle_string( 'ABCDEFGHIKLMNPQRSTVWXYZU' x
          int( $self->profile->length / 20 ) );
   return $random_seq;
}

sub _shuffle_string {
   my $string = shift;
   my @elms = split '', $string;
   return join( '', shuffle @elms );
}

has calibrate_profile => (
   is      => 'rw',
   isa     => 'Bool',
   default => 0,
);

has _hmmer => (
   is         => 'ro',
   isa        => 'Bio::Tools::Run::Hmmer',
   lazy_build => 1,
   handles    => {
      _hmmsearch => 'hmmsearch'
      },
);

has _my_fitness => (
   is => 'ro',
   lazy_build => 1,
   isa => 'CodeRef',
);

sub _build__hmmer {
   my $self    = shift;
   my $hmmfile = File::Temp->new->filename;
   my $hmmer
       = Bio::Tools::Run::Hmmer->new( -hmm => $hmmfile, -quiet => 1 );
   $hmmer->hmmbuild( $self->profile );
   if ( $self->calibrate_profile ) { $hmmer->hmmcalibrate }
   return $hmmer;
}

sub _build__my_fitness {
   my $self = shift;

   my $max_score = $self->_evalue( $self->profile->consensus_string );
   my $min_score = $self->_evalue ($self->_random_seq,);

   return sub {
      my $string = shift;
      my $abs_score = $self->_evalue($string);
      my $score = (( $abs_score - $min_score)/( $max_score - $min_score));
      return $score;
   }
}

sub _evalue {
   my ($self, $string) = @_;
   my $seq = Bio::Seq->new(-id => 'x', -seq => $string);

   # Bio::Search::Hit (We take the highest-scoring hit)
   my $hit = $self->_hmmsearch($seq)->next_result->next_hit;

   # Bio::Search::HSP (High Scoring Pairs, take all)
   my @hsps;
   while (my $hsp = $hit->next_hsp) { push @hsps, $hsp };

   # The global e-value is the sum of logarithms of
   # evalues of every HSP.
   my $log_evalue;
   map { $log_evalue += log($_->evalue)/log(10) } @hsps;

   return $log_evalue;
}



no Moose;
1;
