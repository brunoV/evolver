use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Test::Warn;
use Bio::Tools::Evolver;
use Bio::AlignIO;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);
use Devel::SimpleTrace;

my @align_files = glob('t/profile-test.*');
my $align_file = $align_files[0];
my @seqs_files = glob('t/seqs-test.*');
my $seqs_file  = $seqs_files[0];

my @plugins = qw(Simple Needleman Hmmer);

my $ev;

foreach my $plugin (@plugins) {

   $ev = Bio::Tools::Evolver->new(
      profile    => $seqs_file,
      population => 10,
      fitness    => sub { 1 },
      preserve   => 0,
      cache      => 1,
      profile_algorithm => $plugin,
   );
   lives_ok { $ev->evolve(1) } "Short evolution run: $plugin";

   my @fittest = $ev->getFittest( 2, 1 );
   is( scalar @fittest, 2, 'getFittest with arguments' );
   isa_ok( $fittest[0], 'Bio::Seq' );

   my $fittest = $ev->getFittest;
   isa_ok( $fittest, 'Bio::Seq' );

   # Testing injection.
   $ev = Bio::Tools::Evolver->new(
      profile    => $align_file,
      population => 5,
      fitness    => sub { return 1 },
      cache      => 1,
   );
   my $alignI = Bio::AlignIO->new( -file => "<$align_file" );
   my ($string) = $alignI->next_aln->consensus_string;

   my $seq = Bio::Seq->new( -seq => $string, -id => 'cons' ); my $short_seq = Bio::Seq->new(
      -seq => 'PNYVIKPWLEP',
      -id  => 'shorty',
   );

   dies_ok { $ev->inject('madre santa') } 'Injecting rubbish';
   dies_ok {
      $ev->inject($short_seq)
   } 'Injecting sequences with wrong length';
   warning_like { $ev->inject() } qr/No arguments/i, 'Injecting nothing';

   $ev->evolve(1);
   lives_ok { $ev->inject($seq) } 'Injecting after evolving';

   ($fittest) = $ev->getFittest;
   is( $fittest->seq, $string, 'Injection occured correctly' );

   # Doing it the other way around (inject->evolve)
   $ev = Bio::Tools::Evolver->new(
      profile => $align_file,
      population => 1,
      preserve => 1,
      fitness => sub { shift eq $seq and return 1000; return 0 },
   );

   lives_ok { $ev->inject($seq) } 'Injecting before evolving';
   lives_ok { $ev->evolve(1)    } 'Evolving after injecting';
   ($fittest) = $ev->getFittest;
   is( $fittest->seq, $string, 'Injection occured correctly' );

   # Test terminate function
   $ev = Bio::Tools::Evolver->new(
      profile => $align_file,
      population => 5,
      fitness => sub { return 1 },
      terminate => \&_has_F,
   );

   $ev->inject($seq);
   $ev->evolve();
   is( $ev->generation, 0, 'Terminate function worked' );

}

sub count_hydroph {
   my $string = shift;
   my $count = scalar grep { $_ =~ /[VALI]/ } split '', $string;
   return ( $count / length $string );
}

sub _has_F {
      my $seq = shift;
      my @res = (split '', $seq);
      return 1 if grep { $_ eq 'F' } @res;
      return 0;
}
