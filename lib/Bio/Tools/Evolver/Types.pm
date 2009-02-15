package Bio::Tools::Evolver::Types;
use strict;
use warnings;
use Moose::Role;
use Moose::Util::TypeConstraints;

# BTE.Profile is a filename that exists.
# I should also check that has a sane extension.
subtype 'BTE.Profile'
   => as 'Str'
   => where { -e $_ }
   => message {"Profile file doesn't exist"};

# These are the types that the attr. profile is going to coerce
# into BTE.Profile
subtype 'BTE.Bio.SeqIO'        => as class_type('Bio::SeqIO');
subtype 'BTE.Bio.Seq'          => as class_type('Bio::Seq');
subtype 'BTE.Bio.Seq.ArrayRef' => as 'ArrayRef[BTE.Bio.Seq]';
subtype 'BTE.Bio.AlignIO'      => as class_type('Bio::AlignIO');
subtype 'BTE.Bio.SimpleAlign'  => as class_type('Bio::SimpleAlign');

no Moose;
1;
