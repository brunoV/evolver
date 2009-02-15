package Bio::Tools::Evolver::Profile;
use strict;
use warnings;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Bio::Seq;
use Bio::AlignIO;
use Bio::Tools::Run::Alignment::Clustalw;
use File::Temp;

# This role should provide a 'profile' attribute that accepts
# an alignment filename, a Bio::AlignIO, Bio::SimpleAlign or Bio::SeqIO
# objects or an arrayref of Bio::Seq objects.

# BTE.Profile is a filename that exists.
# I should also check that has a sane extension.
subtype 'BTE.Profile'
   => as 'Str'
   => where { -e $_ }
   => message {"Profile file doesn't exist"};

# This are the types that the attr. profile is going to coerce
# into BTE.Profile
subtype 'BTE.Bio.SeqIO'        => as class_type('Bio::SeqIO');
subtype 'BTE.Bio.Seq'          => as class_type('Bio::Seq');
subtype 'BTE.Bio.Seq.ArrayRef' => as 'ArrayRef[BTE.Bio.Seq]';
subtype 'BTE.Bio.AlignIO'      => as class_type('Bio::AlignIO');
subtype 'BTE.Bio.SimpleAlign'  => as class_type('Bio::SimpleAlign');

has 'profile' => (
   is       => 'ro',
   isa      => 'BTE.Profile',
   required => 1,
   coerce   => 1,
);

# Coerce to subtypes to BTE.Profile
coerce 'BTE.Profile'
    => from 'BTE.Bio.SeqIO'
       => via { &_coerce( \&_BioSeqIO, $_[0] ) }
    => from 'BTE.Bio.Seq.ArrayRef'
       => via { &_coerce( \&_BioSeqArrayRef, $_[0] ) }
    => from 'BTE.Bio.AlignIO'
       => via { &_coerce( \&_BioAlignIO, $_[0] ) }
    => from 'BTE.Bio.SimpleAlign'
       => via { &_coerce( \&_BioSimpleAlign, $_[0] ) };

sub _coerce {
   my ( $coderef, $arg ) = @_;
   my $tempfile = File::Temp->new->filename;
   my $alignIO  = Bio::AlignIO->new(
      -file   => ">$tempfile",
      -format => "msf",
   );
   $alignIO->write_aln( $coderef->($arg) );
   return $tempfile;
}

sub _BioSimpleAlign {$_}

sub _BioAlignIO { $_->next_aln }

sub _BioSeqIO {
   my $seqI = shift;
   my $factory = Bio::Tools::Run::Alignment::Clustalw->new( quiet => 1 );

   my $seqs;
   while ( my $seq = $seqI->next_seq ) { push @$seqs, $seq }
   my $aln = $factory->align($seqs);

   return $aln;
}

sub _BioSeqArrayRef {
   my $seqs = shift;
   my $factory = Bio::Tools::Run::Alignment::Clustalw->new( quiet => 1 );

   my $aln = $factory->align($seqs);

   return $aln;
}

no Moose;
1;
