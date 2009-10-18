use Test::More;
use Evolver;
use strict;
use warnings;

my @align_files = glob('t/profile-test.*');
my $align_file = $align_files[0];

my $e = Evolver->new(
    fitness             => sub { 1 },
    profile_algorithm   => 'None',
    profile             => $align_file,
    inject              => ['VIKP', 'ALEP'],
    inject_consensus    => 0,
    inject_profile_seqs => 1,
    population_size     => 20,
);

my %seqs =
    map { my $s = $_->seq; $s =~ s/[-.]//g; $s => 1 } $e->profile->each_seq;

@seqs{qw(VIKP ALEP)} = (1, 1);

my @iseqs = map { $_->{seq} } $e->current_population;

ok( %seqs ~~ @iseqs );

done_testing;
