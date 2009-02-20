package Bio::Tools::Evolver::Types;
use strict;
use warnings;
use Moose::Role;
use Moose::Util::TypeConstraints;
use File::Basename;

# BTE.Profile is a filename that exists.
# I should also check that has a sane extension.

# These are the types that the attr. profile is going to coerce
# into BTE.Profile
subtype 'BTE.ProfileFile'      => as 'Str' => where { validate_aln($_) };
subtype 'BTE.Bio.SeqIO'        => as class_type('Bio::SeqIO');
subtype 'BTE.Bio.Seq'          => as class_type('Bio::Seq');
subtype 'BTE.Bio.Seq.ArrayRef' => as 'ArrayRef[BTE.Bio.Seq]';
subtype 'BTE.Bio.AlignIO'      => as class_type('Bio::AlignIO');
subtype 'BTE.Bio.SimpleAlign'  => as class_type('Bio::SimpleAlign');

subtype 'BTE.Probability'      => as 'Str' => where { $_ < 1 and $_ > 0 };

sub validate_aln {

   # Uninplemented. I'm planning on analyzing the file's extensions
   # and try to throw exceptions if they are not recognized. The problem
   # arises with formats such as FASTA, that can be both an alignment
   # or a sequence ¿default to sequence? I guess so, in the worst case
   # it will realign it; if the user really wants to keep their alignment
   # intact, save it in a better format, damn it.
   return 1;
}

# Scoring Matrix Types
subtype 'BTE.Bio.Matrix.Scoring' => as class_type('Bio::Matrix::Scoring');
subtype 'BTE.MatrixFile'
   => as 'Str'
   => where { validate_mfile($_) }
   => message {"File $_ doesn't exist"};
subtype 'BTE.Bio.Matrix.IO' => as class_type('Bio::Matrix::IO');
subtype 'BTE.MatrixName' => 'Str' => where { validate_mname($_) };
subtype 'BTE.Algorithm.NeedlemanWunsch'
   => as class_type('Algorithm::NeedlemanWunsch');


sub validate_mfile { return 1 if -e $_[0] }

sub validate_mname {
   my $name     = shift;
   my @matrixes = qw(BLOSUM62 BLOSUM80 BLOSUM90 BLOSUM45 BLOSUM50);
   return grep { $name eq $_ } @matrixes;
}

no Moose;
1;
