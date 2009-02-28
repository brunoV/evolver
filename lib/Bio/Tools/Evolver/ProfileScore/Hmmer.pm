package Bio::Tools::Evolver::ProfileScore::Hmmer;
use Moose::Role;
requires '_build__my_fitness';
with 'Bio::Tools::Evolver::RandomSeq';

use Bio::Tools::Run::Hmmer;
use File::Temp;

## _min_score

sub _build__min_score {
   my $self = shift;
   return $self->_profile_score($self->_random_seq);
}

## _max_score

sub _build__max_score {
   my $self = shift;
   return $self->_profile_score($self->profile->consensus_string);
}

## _profile_score

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

sub _build__hmmer {
   my $self    = shift;
   my $hmmfile = File::Temp->new->filename;
   my $hmmer
       = Bio::Tools::Run::Hmmer->new( -hmm => $hmmfile, -quiet => 1 );
   $hmmer->hmmbuild( $self->profile );
   if ( $self->calibrate_profile ) { $hmmer->hmmcalibrate }
   return $hmmer;
}

sub _profile_score {
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
