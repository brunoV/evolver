use strict;
use warnings;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);
use Test::More qw(no_plan);
use Test::Exception;
use Test::Warn;

my @align_files = glob('t/profile-test.*');
my @seqs_files = glob('t/seqs-test.*');
my $seqs_file  = $seqs_files[0];
my $align_file = 't/profile-test.phy';

{
   package Bogus;
   use Moose;
   use Bio::AlignIO;
   with 'Bio::Tools::Evolver::ProfileScore::Hmmer';

   has profile => (
      is         => 'ro',
      isa        => 'Bio::SimpleAlign',
      lazy_build => 1,
   );

   sub _build_profile {
      my $self = shift;
      my $alignI = Bio::AlignIO->new( -file => "<$align_file" );
      return $alignI->next_aln;
   }
}

my $tester;
lives_ok { $tester = Bogus->new } 'Class new OK';
can_ok( 'Bogus', qw(_hmmer calibrate_profile profile) );

lives_ok { $tester->profile } 'Class has profile';
is($tester->profile->consensus_string,
   'STHASGFFFFHPTKMAKSTNYFLISCLLFVLFNGCMGEGRFREFQQGNECQIDRLTALEPTNRIQAEAGLTEVWDSNEQEFRCA',
   'Profile is OK'
);

my $seq = Bio::SeqIO->new(-file => "<$seqs_file")->next_seq;

lives_ok { $tester->_evalue($seq->seq) } 'Worked';
lives_ok { $tester->_my_fitness->($seq->seq) } 'Woah, worked';
print $tester->_my_fitness->($seq->seq), "\n";
print $tester->_my_fitness->($tester->_random_seq), "\n";
