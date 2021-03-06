package Evolver::Types;

use MooseX::Types -declare => [qw( ProfileFile BioSeqIO BioSeq
    ArrayRefofBioSeq BioMatrixScoring MatrixFile BioMatrixIO
    AlgorithmNeedlemanWunsch Probability BioAlignIO BioSimpleAlign
    MatrixName Hmmer Aligner
)];

use MooseX::Types::Moose qw(ArrayRef Str);

use Class::Autouse qw(Bio::Seq Bio::SeqIO Bio::AlignIO Bio::Matrix::IO
Bio::Tools::Run::Alignment::Clustalw Bio::Tools::GuessSeqFormat
File::Temp);

use File::Basename qw(fileparse);
use Carp qw(croak);
use namespace::autoclean;

# Alignment types.
class_type BioSeqIO,       { class => 'Bio::SeqIO'       };
class_type BioSeq,         { class => 'Bio::Seq'         };
class_type BioAlignIO,     { class => 'Bio::AlignIO'     };
class_type BioSimpleAlign, { class => 'Bio::SimpleAlign' };

subtype ProfileFile,      as Str;
subtype ArrayRefofBioSeq, as ArrayRef[BioSeq];

# Scoring Matrix Types
class_type BioMatrixScoring, { class => 'Bio::Matrix::Scoring' };
class_type BioMatrixIO,      { class => 'Bio::Matrix::IO'      };
class_type AlgorithmNeedlemanWunsch, 
    { class => 'Algorithm::NeedlemanWunsch' };

subtype MatrixName, as Str, where { _validate_mname($_) };
subtype MatrixFile,
    as Str,
    where { _validate_mfile($_) },
    message {"File $_ doesn't exist"};

# Misc. types
subtype Probability, as Str, where { $_ < 1 and $_ > 0 };
class_type Hmmer,   { class => 'Bio::Tools::Run::Hmmer' };
class_type Aligner, { class => 'Evolver::Aligner' };

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
   # UPDATE: Unfortunately, it also shrinked the id of each sequence
   # aggresively. Since commenting out the conversion code didn't make
   # any test fail, I'll leave it like this for now.
   my $alnI = Bio::AlignIO->new( -file => "<$file" );
#   my $tmpfile = File::Temp->new(
#      TEMPLATE => 'XXXXXX',
#      SUFFIX   => '.phy',
#   )->filename;
#   my $alnO = Bio::AlignIO->new(
#      -file   => ">$tmpfile",
#      -format => 'phylip',
#   );
#   $alnO->write_aln( $alnI->next_aln );
#   $alnI = Bio::AlignIO->new(
#      -file   => "<$tmpfile",
#      -format => 'phylip',
#   );
#
   my $aln = $alnI->next_aln;
#   unlink $tmpfile;
   return $aln;
}

sub _seqarrayref_to_aln {
   my $seqs = shift;

   my %params = ( quiet => 1, output => 'clustalw' );
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

# Coerce subtypes to BioSimpleAlign
coerce BioSimpleAlign,
    from BioSeqIO,         via { _seqarrayref_to_aln( _seqI_to_seqarrayref($_) ) },
    from ArrayRefofBioSeq, via { _seqarrayref_to_aln($_) },
    from BioAlignIO,       via { $_->next_aln },
    from ProfileFile,      via { _filename_to_aln($_) };

# Coerce to Matrix scoring.
coerce BioMatrixScoring,
    from MatrixFile,  via { parse_matrixfile( $_[0] ) },
    from BioMatrixIO, via { return $_[0]->next_matrix },
    from MatrixName,  via { parse_matrixfile( _getpath( $_[0] ) ) };

# Type validations.
sub _validate_mfile { return 1 if -e $_[0] }

sub _validate_mname {
   my $name     = shift;
   my @matrixes = qw(BLOSUM62 BLOSUM80 BLOSUM90 BLOSUM45 BLOSUM50);
   return grep { $name eq $_ } @matrixes;
}

__PACKAGE__->meta->make_immutable;
