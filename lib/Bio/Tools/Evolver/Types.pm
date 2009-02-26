package Bio::Tools::Evolver::Types;
use strict;
use warnings;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Bio::Seq;
use Bio::AlignIO;
use Bio::Matrix::IO;
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::Tools::GuessSeqFormat;

use File::Basename;
use File::Temp;
use Carp qw(croak);

# Alignment types.
subtype 'BTE::ProfileFile' => as 'Str';
subtype 'BTE::Bio::SeqIO'         => as class_type('Bio::SeqIO');
subtype 'BTE::Bio::Seq'           => as class_type('Bio::Seq');
subtype 'BTE::Bio::Seq::ArrayRef' => as 'ArrayRef[BTE::Bio::Seq]';
subtype 'BTE::Bio::AlignIO'       => as class_type('Bio::AlignIO');
subtype 'BTE::Bio::SimpleAlign'   => as class_type('Bio::SimpleAlign');

# Scoring Matrix Types
subtype 'BTE::Bio::Matrix::Scoring' =>
    as class_type('Bio::Matrix::Scoring');
subtype 'BTE::MatrixFile' => as 'Str' => where { _validate_mfile($_) } =>
    message {"File $_ doesn't exist"};
subtype 'BTE::Bio::Matrix::IO' => as class_type('Bio::Matrix::IO');
subtype 'BTE::MatrixName' => as 'Str' => where { _validate_mname($_) };
subtype 'BTE::Algorithm::NeedlemanWunsch' =>
    as class_type('Algorithm::NeedlemanWunsch');

subtype 'BTE::Probability' => as 'Str' => where { $_ < 1 and $_ > 0 };

# Coercion coderefs. I couldn't use proper subs because it would look
# for them in the applying module, even after prepending this module's name.
sub parse_matrixfile {

   #my $parse_matrixfile_sub = sub {
   my $file = shift;
   my $parser = Bio::Matrix::IO->new( -file => $file )
       or die "Couldn't open scoring matrix $file : $!";
   return $parser->next_matrix;
}

my %is_alignment = (    # These are unambiguous alignment formats.
   stockholm => 1,
   selex     => 1,
   prodom    => 1,
   phylip    => 1,
   pfam      => 1,
   nexus     => 1,
   msf       => 1,
   mega      => 1,
   mase      => 1,
   hmmer     => 1,
   gde       => 1,
   gcgblast  => 1,
   clustalw  => 1,
   blast     => 1,
);

sub _alnfile_to_aln {
   my $file = shift;

   # Best results if I convert all alignments
   # to phylip format, that plays nicely
   # with sequence gaps.
   my $alnI = Bio::AlignIO->new( -file => "<$file" );
   my $tmpfile = File::Temp->new(
      TEMPLATE => 'XXXXXX',
      SUFFIX   => '.phy',
   )->filename;
   my $alnO = Bio::AlignIO->new(
      -file   => ">$tmpfile",
      -format => 'phylip',
   );
   $alnO->write_aln( $alnI->next_aln );
   $alnI = Bio::AlignIO->new(
      -file   => "<$tmpfile",
      -format => 'phylip',
   );

   my $aln = $alnI->next_aln;
   unlink $tmpfile;
   return $aln;
}

sub _seqarrayref_to_aln {
   my $seqs = shift;

   my %params = ( quiet => 1, output => 'phylip' );
   my $factory = Bio::Tools::Run::Alignment::Clustalw->new(%params);

   my $aln = $factory->align($seqs);

   return $aln;
}

sub _seqI_to_seqarrayref {
   my $seqI = shift;
   my $seqarrayref;

   while ( my $seq = $seqI->next_seq ) {
      push @$seqarrayref, $seq;
   }
   return $seqarrayref;
}

sub _filename_to_aln {

   # I'll try to guess whether the file should be opened as an alignment,
   # or as a sequence and then align it.
   my $file = shift;
   my $guesser = Bio::Tools::GuessSeqFormat->new( -file => $file );
   my ( $aln, $seqI );
   if ( defined $guesser->guess && defined $is_alignment{ $guesser->guess } ) {

      # The file is an alignment, try to open it as such.
      eval { $aln = _alnfile_to_aln($file) };
      if ($@) {

         # It went wrong, try to open it as a sequence and align it
         $seqI = Bio::SeqIO->new( -file => $file )
             or croak "Couldn't open file $file";
         $aln = _seqarrayref_to_aln( _seqI_to_seqarrayref($seqI) );
      }
   } else {

      # The fromat is not alignment-exclusive, so let's treat it
      # as a sequence and align it.
      $seqI = Bio::SeqIO->new( -file => $file )
          or croak "Couldn't open file $file";
      $aln = _seqarrayref_to_aln( _seqI_to_seqarrayref($seqI) );
   }
   return $aln;
}

sub _getpath {
   my $matrix_name = shift;
   my $full_path   = __FILE__;
   my ( $module_file, $directories, $suffix ) = fileparse($full_path);
   if ($directories) { return $directories . $matrix_name }
   return $matrix_name;
}

# Type Coercions

# Coerce subtypes to BTE.Bio.SimpleAlign
coerce 'BTE::Bio::SimpleAlign' => from 'BTE::Bio::SeqIO' =>
    via { _seqarrayref_to_aln( _seqI_to_seqarrayref($_) ) } => from
    'BTE::Bio::Seq::ArrayRef' => via { _seqarrayref_to_aln($_) } => from
    'BTE::Bio::AlignIO'       => via { $_->next_aln }           => from
    'BTE::ProfileFile'        => via { _filename_to_aln($_) };

# Coerce to Matrix scoring.
coerce 'BTE::Bio::Matrix::Scoring' => from 'BTE::MatrixFile' =>
    via { parse_matrixfile( $_[0] ) } => from 'BTE::Bio::Matrix::IO' =>
    via { return $_[0]->next_matrix } => from 'BTE::MatrixName' =>
    via { parse_matrixfile( _getpath( $_[0] ) ) };

# Type validations.

sub _validate_mfile { return 1 if -e $_[0] }

sub _validate_mname {
   my $name     = shift;
   my @matrixes = qw(BLOSUM62 BLOSUM80 BLOSUM90 BLOSUM45 BLOSUM50);
   return grep { $name eq $_ } @matrixes;
}

no Moose;
1;
