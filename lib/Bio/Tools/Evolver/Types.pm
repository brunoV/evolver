package Bio::Tools::Evolver::Types;
use strict;
use warnings;
use Moose::Role;
use Moose::Util::TypeConstraints;
use File::Basename;

use Bio::Seq;
use Bio::AlignIO;
use Bio::Matrix::IO;
use Bio::Tools::Run::Alignment::Clustalw;

use File::Temp;

# Alignment types.
subtype 'BTE::ProfileFile'        => as 'Str' => where { validate_aln($_) };
subtype 'BTE::Bio::SeqIO'         => as class_type('Bio::SeqIO');
subtype 'BTE::Bio::Seq'           => as class_type('Bio::Seq');
subtype 'BTE::Bio::Seq::ArrayRef' => as 'ArrayRef[BTE::Bio::Seq]';
subtype 'BTE::Bio::AlignIO'       => as class_type('Bio::AlignIO');
subtype 'BTE::Bio::SimpleAlign'   => as class_type('Bio::SimpleAlign');

# Scoring Matrix Types
subtype 'BTE::Bio::Matrix::Scoring' => as class_type('Bio::Matrix::Scoring');
subtype 'BTE::MatrixFile'
   => as 'Str'
   => where { validate_mfile($_) }
   => message {"File $_ doesn't exist"};
subtype 'BTE::Bio::Matrix::IO' => as class_type('Bio::Matrix::IO');
subtype 'BTE::MatrixName' => as 'Str' => where { validate_mname($_) };
subtype 'BTE::Algorithm::NeedlemanWunsch'
   => as class_type('Algorithm::NeedlemanWunsch');

subtype 'BTE::Probability'      => as 'Str' => where { $_ < 1 and $_ > 0 };

# Coercion coderefs. I couldn't use proper subs because it would look
# for them in the applying module.
my $parse_matrixfile_sub = sub {
   my $file = shift;
   my $parser = Bio::Matrix::IO->new( -file => $file )
       or die "Couldn't open scoring matrix $file : $!";
   return $parser->next_matrix;
};

my $profile_sub = sub {
   my $file = shift;

   my $alnI = Bio::AlignIO->new(-file => "<$file");
   my $tmpfile = File::Temp->new(
      TEMPLATE => 'XXXXXX',
      SUFFIX => '.phy',
   )->filename;
   my $alnO = Bio::AlignIO->new(
      -file => ">$tmpfile",
      -format => 'phylip',
   );
   $alnO->write_aln($alnI->next_aln);
   $alnI = Bio::AlignIO->new(
      -file => "<$tmpfile",
      -format => 'phylip',
   );

   my $aln = $alnI->next_aln;
   unlink $tmpfile;
   return $aln;
};

my $bioseqio_sub = sub {
   my $seqI = shift;

   my %params = ( quiet => 1, output => 'phylip' );
   my $factory = Bio::Tools::Run::Alignment::Clustalw->new( %params );
   my $seqs;
   while ( my $seq = $seqI->next_seq ) { push @$seqs, $seq }
   my $aln = $factory->align($seqs);

   return $aln;
};

my $bioseqarrayref_sub = sub {
   my $seqs = shift;

   my %params = ( quiet => 1, output => 'phylip' );
   my $factory = Bio::Tools::Run::Alignment::Clustalw->new( %params );

   my $aln = $factory->align($seqs);

   return $aln;
};

my $getpath_sub = sub {
   my $matrix_name = shift;
   my $full_path = __FILE__;
   my ($module_file, $directories, $suffix) = fileparse($full_path);
   if ($directories) { return $directories . $matrix_name };
   return $matrix_name;
};


# Type Coercions

# Coerce subtypes to BTE.Bio.SimpleAlign
coerce 'BTE::Bio::SimpleAlign'
    => from 'BTE::Bio::SeqIO'
       => via { $bioseqio_sub->($_)  }
    => from 'BTE::Bio::Seq::ArrayRef'
       => via { $bioseqarrayref_sub->($_) }
    => from 'BTE::Bio::AlignIO'
       => via { $_->next_aln  }
    => from 'BTE::ProfileFile'
       => via { $profile_sub->($_) };

# Coerce to Matrix scoring.
coerce 'BTE::Bio::Matrix::Scoring'
   => from 'BTE::MatrixFile' => via { $parse_matrixfile_sub->( $_[0] ) }
   => from 'BTE::Bio::Matrix::IO' =>  via { return $_[0]->next_matrix }
   => from 'BTE::MatrixName'  => via { $parse_matrixfile_sub ->( $getpath_sub->( $_[0] ) ) };

# Type validations.
sub validate_aln {

   # Uninplemented. I'm planning on analyzing the file's extensions
   # and try to throw exceptions if they are not recognized. The problem
   # arises with formats such as FASTA, that can be both an alignment
   # or a sequence ¿default to sequence? I guess so, in the worst case
   # it will realign it; if the user really wants to keep their alignment
   # intact, save it in a better format, damn it.
   return 1;
}

sub validate_mfile { return 1 if -e $_[0] }

sub validate_mname {
   my $name     = shift;
   my @matrixes = qw(BLOSUM62 BLOSUM80 BLOSUM90 BLOSUM45 BLOSUM50);
   return grep { $name eq $_ } @matrixes;
}


no Moose;
1;
