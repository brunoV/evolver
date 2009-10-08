use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Test::Warn;
use Evolver;
use Bio::AlignIO;

my @align_files = glob('t/profile-test.*');
my $align_file = $align_files[0];
my @seqs_files = glob('t/seqs-test.*');
my $seqs_file  = $seqs_files[0];

# Test constructor and passing different profile types to
# the profile attribute.
my $ev;

# 1.  Passing filenames.
# 1.1 Alignment files.
lives_ok {
   $ev = Evolver->new(
      profile => $_,
      fitness => sub { return 1 },
   ) for @align_files;
}
'Profile: alignment files';
isa_ok( $ev, 'Evolver', "Constructor" );
isa_ok( $ev->profile, 'Bio::SimpleAlign' );

# 1.2 Sequence files.
lives_ok {
   $ev = Evolver->new(
      profile => $seqs_file,
      fitness => sub { return 1 },
   );
} 'Profile: sequence files';

# 2. Passing an AlignIO object.
my $alignI = Bio::AlignIO->new( -file => "<$align_file" );
lives_ok {
   $ev = Evolver->new(
      profile => $alignI,
      fitness => sub { return 1 },
   );
}
'Profile: AlignIO object';

# 3. Passing a SimpleAlign object.
$alignI = Bio::AlignIO->new( -file => "<$align_file" );
my $aln = $alignI->next_aln;
lives_ok {
   $ev = Evolver->new(
      profile => $aln,
      fitness => sub { return 1 },
   );
}
'Profile: SimpleAlign object';

# 4. Passing a SeqIO object.
my $seqI = Bio::SeqIO->new( -file => $seqs_file );
lives_ok {
   $ev = Evolver->new(
      profile => $seqI,
      fitness => sub { return 1 },
   );
}
'Profile: SeqIO object';

# 5. Passing an arrayref of Bio::Seq objects.
$seqI = Bio::SeqIO->new( -file => $seqs_file );
my @seqs;
while ( my $seq = $seqI->next_seq ) { push @seqs, $seq }
ok( @seqs > 1, "File $seqs_file has more than one sequence" );
isa_ok( $seqs[1], 'Bio::Seq' );
lives_ok {
   $ev = Evolver->new(
      profile => [@seqs],
      fitness => sub { return 1 },
   );
}
'Profile: Seq object';

# 6. Passing inexistent or empty files
throws_ok { 
   $ev = Evolver->new(
      profile => 'inexistent-file',
      fitness => sub { return 1 },
   );
} 'Bio::Root::Exception', 'Profile: inexistent file';

throws_ok {
   $ev = Evolver->new(
      profile => 't/bogus-seq.bogus',
      fitness => sub { return 1 },
   );
} 'Bio::Root::Exception', 'Profile: empty file';
