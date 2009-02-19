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
   # Uninplemented
   return 1
}

no Moose;
1;
