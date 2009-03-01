use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Test::Warn;
use Bio::Tools::Evolver;
use lib qw(/home/bruno/lib/Bio-Tools-Evolver/lib);
use Devel::SimpleTrace;
use File::Basename qw(dirname);

my @align_files = glob('t/profile-test.*');
my $align_file = 't/profile-test.sto';
my @seqs_files = glob('t/seqs-test.*');
my $seqs_file  = $seqs_files[0];

my @plugins = qw(Simple Needleman Hmmer);

foreach my $plugin (@plugins) {

   test_evolve($align_file, $plugin);

   test_getFittest($seqs_file, $plugin);
  
   test_injection($seqs_file, $plugin);

   test_terminate($seqs_file, $plugin);

}

sub test_evolve {
   my ($profile, $plugin) = @_;

   my $ev = Bio::Tools::Evolver->new(
      profile    => $profile,
      population => 3,
      fitness    => \&count_hydroph,
      preserve   => 0,
      cache      => 1,
      inject_consensus => 0,
      profile_algorithm => $plugin,
   );
   lives_ok { $ev->evolve(1) } "Short evolution run: $plugin";
   lives_ok { $ev->evolve(1) } "Second evolution run: $plugin";
   is( $ev->generation, 2, "Evolved two generations: $plugin" );
}

sub test_injection {
   my ($profile, $plugin) = @_;

   my $ev = Bio::Tools::Evolver->new(
      profile    => $profile,
      population => 5,
      fitness    => sub { return 1 },
      cache      => 1,
      profile_algorithm => $plugin,
      inject_consensus => 0,
   );
   my ($string) = $ev->profile->consensus_string;

   my $seq = Bio::Seq->new( -seq => $string, -id => 'cons' );
   my $short_seq = Bio::Seq->new(
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

   my ($fittest) = $ev->getFittest;
   is( $fittest->seq, $string, "Injection occured correctly: $plugin" );

   # Doing it the other way around (inject->evolve)
   $ev = Bio::Tools::Evolver->new(
      profile => $profile,
      population => 1,
      preserve => 1,
      profile_algorithm => $plugin,
      inject_consensus => 0,
      fitness => sub { shift eq $seq and return 1000; return 0 },
   );

   lives_ok { $ev->inject($seq) } 'Injecting before evolving';
   lives_ok { $ev->evolve(1)    } 'Evolving after injecting';
   ($fittest) = $ev->getFittest;
   is( $fittest->seq, $string, "Injection occured correctly: $plugin" );
}

sub test_getFittest {
   my ($profile, $plugin) = @_;

   my $ev = Bio::Tools::Evolver->new(
      profile => $profile,
      population => 5,
      fitness => sub {1},
      profile_algorithm => $plugin,
   );

   $ev->evolve(1);

   my @fittest = $ev->getFittest( 1, 1 );
   is( scalar @fittest, 1, 'getFittest with arguments' );
   isa_ok( $fittest[0], 'Bio::Seq' );

   my $fittest = $ev->getFittest;
   isa_ok( $fittest, 'Bio::Seq' );
}

   sub test_terminate {
      my ($profile, $plugin) = @_;

      # Test terminate function: here the terminate function is
      # looking for a sequence that has an 'F'. Since the input
      # profile already has several, asking to evolve indefinately
      # (calling evolve without an argument) should stop before
      # doing a single generation, since the starting sequences already
      # satisfy the terminate function.

      my $ev = Bio::Tools::Evolver->new(
         profile => $profile,
         population => 5,
         fitness => sub { return 1 },
         inject_consensus => 1,
         terminate => \&_has_F,
      );

      $ev->evolve();
      is( $ev->generation, 0, 'Terminate function worked' );
   }

sub count_hydroph {
   my $string = shift;
   my $count = scalar grep { $_ =~ /[VALI]/ } split '', $string;
   return ( $count / length $string );
}

sub _has_F {
      my $seq_obj = shift;
      my @res = (split '', $seq_obj->seq);
      return 1 if grep { $_ eq 'F' } @res;
      return 0;
}
