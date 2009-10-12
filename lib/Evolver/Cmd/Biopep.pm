package Evolver::Cmd::Biopep;
use Moose;

extends qw(Evolver::Cmd::Base);

use MooseX::Types::Moose qw(Str HashRef);
use MooseX::Types::Path::Class qw(File);
use namespace::autoclean;
use Modern::Perl;

use Dir::Self;
use Bio::Seq;
use Bio::SeqFeature::Generic;

# This has to be globally accesible since fitness function doesn't
# have acess to $self
my $db;

sub BUILD {
    my $self = shift;

    $db = $self->db;
}

sub _build_evolver {
    my $self = shift;

    my $ev = Evolver->new(
        profile      => $self->infile,
        fitness      => \&f,
        fitness_name => $self->activity,
    );

    return $ev;
}

has _dbfile => (
   is  => 'ro',
   isa => File,
   coerce  => 1,
   default => __DIR__ . '/biopep_db',
);

has db => (
   is  => 'ro',
   isa => HashRef,
   lazy_build => 1,
);

has activity => (
    is  => 'ro',
    isa => Str,
    required => 1,
);

sub _build_db {
    my $self = shift;

    my $db = parse_database( $self->_dbfile );

    # Remove all peptides of undesired activity
    foreach my $seq ( keys %$db ) {
        delete $db->{$seq} unless $db->{$seq}->[1] =~ $self->activity;
    }

    warn "There are: ", scalar keys %$db, " peptides in db\n";

    return $db;
}

sub f {
    my $seq = shift;

    # Annotate the sequence using the in-memory database.
    my $seq_obj = annotate_seq(\$seq);

    # Count all the useful peptides (this is a naïve approach).
    my $biopep_count = get_encrypted_biopeps($seq_obj);

    return ( $biopep_count / length $seq );
}

sub f_EC50 {
    # unfinished
    my $seq = shift;
    my $seq_obj = annotate_seq(\$seq);

}

sub parse_database {

# Extract the sequence, origin, EC50 and biological activity of every peptide in the flatfile database.
# Takes a scalar with filename as an argument.
    my $dbfile = shift;

    my @lines = $dbfile->slurp;

    my %db;
    foreach my $line (@lines) {

        # Parse the important tab-delimited fields
        $line =~ /^.*\t{1}(.*)\t{1}.*\t{1}.*\t{1}(.*)\t{1}(.*)\t{1}(.*)$/;
        my ( $origin, $EC50, $activity, $sequence ) = ( $1, $2, $3, $4 );

        #remove leading and trailing spaces from text fields
        $origin   =~ s/^\s+|\s+$//g;
        $activity =~ s/^\s+|\s+$//g;

        #remove any spaces from number and sequence fields.
        $EC50     =~ s/\s//g;
        $sequence =~ s/\s//g;

        $db{$sequence} = [ $origin, $activity, $EC50 ];
    }

    return \%db;
}

sub annotate_seq {

    # Finds those peptides that are encrypted in the query sequence and
    # adds the appropiate annotation. Takes a sequence-object and a
    # properly-built hash reference. Uses subroutine 'find'.

    my $seq_ref = shift;
    my $seq_obj = Bio::Seq->new(-seq => $$seq_ref);

    while ( my ( $peptide, $data ) = each %$db ) {

        # returns array of end position in the query sequence for any
        # peptide in the database
        my $hits = find( \$peptide, $seq_ref );

        # Add a feature for each hit of each peptide found.
        foreach my $end (@$hits) {

            # calculate the start from the end and the peptide length
            my $start = $end - length($peptide) + 1;

            # Add a feature to the sequence-object with the information
            # of the biopeptide found.

            $seq_obj->add_SeqFeature(
                new Bio::SeqFeature::Generic(
                    -primary_tag => 'Biopeptide',
                    -tag         => {
                        'Sequence' => $peptide,
                        'Origin'   => $data->[0],
                        'Activity' => $data->[1],
                        'EC50'     => $data->[2]
                    },
                    -start => $start,
                    -end   => $end
                )
            );
        }
    }
    return $seq_obj;
}

sub find {

    # Finds a a string inside another and returns an array with the
    # position of the last character of each match.

    my ( $substr, $string ) = @_;
    my @positions;

    while ( $$string =~ /$$substr/gi ) {
        push @positions, pos($$string);
        pos($$string) = pos($$string) + 1;
    }

    return \@positions;
}

sub get_encrypted_biopeps {
    # From a Bio::Seq object, return a list of biopeptide features.

    my $seq_obj = shift;
    my @biopeps = grep { $_->primary_tag eq "Biopeptide" }
        $seq_obj->get_SeqFeatures;

    return @biopeps;
}

__PACKAGE__->meta->make_immutable;
1;
