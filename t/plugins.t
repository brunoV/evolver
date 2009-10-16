use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use Evolver;
use File::Basename qw(dirname);

my @align_files = glob('t/profile-test.*');
my $align_file  = 't/profile-test.sto';
my @seqs_files  = glob('t/seqs-test.*');
my $seqs_file   = $seqs_files[0];

my @plugins = qw(Hmmer None);

foreach my $plugin (@plugins) {
    diag("Testing plugin $plugin\n");

    test_evolve($align_file, $plugin);

    test_fittest($seqs_file, $plugin);

    test_terminate($seqs_file, $plugin);
}

TODO: {
    local $TODO = 'Algorithms Needleman, Simple, Clustalw';

    @plugins = qw(Simple Needleman Clustalw);

    lives_ok {

        foreach my $plugin (@plugins) {
            diag("Testing plugin $plugin\n");

            test_evolve($align_file, $plugin);

            test_fittest($seqs_file, $plugin);

            test_terminate($seqs_file, $plugin);
        }
    }
}

sub test_evolve {
   my ($profile, $plugin) = @_;

   my $ev = Evolver->new(
      profile    => $profile,
      population_size => 3,
      fitness    => sub { 1 },
      preserve   => 0,
      cache      => 1,
      inject_consensus => 1,
      profile_algorithm => $plugin,
   );

   is(
       $ev->fittest_seq,
       $ev->profile->consensus_string,
       "Injecting consensus works"
   );

   lives_ok { $ev->evolve(1) } "Short evolution run: $plugin";
   lives_ok { $ev->evolve(1) } "Second evolution run: $plugin";
   is( $ev->generation, 2, "Evolved two generations: $plugin" );
}

sub test_fittest {
   my ($profile, $plugin) = @_;

   my $ev = Evolver->new(
      profile => $profile,
      fitness => sub {1},
      population_size   => 5,
      profile_algorithm => $plugin,
   );

   $ev->evolve(1);

   my @fittest = $ev->fittest( 1 );
   is( scalar @fittest, 1, 'fittest with arguments' );

   my $fittest = $ev->fittest;
   ok( defined $fittest->{seq} );
   is( ref $fittest->{score}, 'HASH' );
   ok( defined $fittest->{score}->{custom}   );
   ok( defined $fittest->{score}->{total}    );
}

sub test_terminate {
    my ($profile, $plugin) = @_;

    # Test terminate function: here the terminate function is
    # looking for a sequence that has an 'F'. Since the input
    # profile already has several, asking to evolve indefinately
    # (calling evolve without an argument) should stop before
    # doing a single generation, since the starting sequences already
    # satisfy the terminate function.

    my $ev = Evolver->new(
       profile => $profile,
       fitness => sub { return 1 },
       population_size  => 5,
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
      my $m   = shift;
      my @res = (split '', $m->fittest->{seq});
      return 1 if grep { $_ eq 'F' } @res;
      return 0;
}

done_testing();
