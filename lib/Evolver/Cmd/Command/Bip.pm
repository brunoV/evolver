package Evolver::Cmd::Command::Bip;
use Moose;

extends qw(Evolver::Cmd::Base);

use Modern::Perl;
use YAML::Any;
use List::Util qw(min max);
use Bio::Tools::SeqStats;

use Memoize;
memoize('_score_boundries');

use namespace::autoclean;

# Fitting function for the optimization of total BiP binding score.

sub _build_evolver {
    my $self = shift;

    my $ev = Evolver->new(
        profile => $self->infile,
        fitness => \&f,
    );

    return $ev;
}

my $score_file = join( '', <DATA> );
my $score_of   = Load($score_file);

sub f {
    my $seq = shift;

    my $score       = total_bip_score(\$seq);
    my ($min, $max) = _score_boundries(\$seq);
    my $normalized  = ( $score - $min ) / ( $max - $min );

    return $normalized;
}

sub total_bip_score {
    my $seq = shift;
    my $it = subsequence_iterator( $$seq, 7, 1 );
    my $score;

    while ( my $peptide = $it->() ) {
        $score += peptide_score($peptide);
    }

    return $score;
}

sub peptide_score {

    # Calculate the BiP binding score for a given peptide 
    my $peptide = shift;
    my @residues = split( '', $peptide );
    my ( $peptide_score, $i ) = (0, 0);

    foreach my $residue (@residues) {
        $peptide_score += $score_of->{$residue}[$i];
        ++$i;
    }

    return $peptide_score;
}

sub subsequence_iterator {
    my ( $sequence, $window_size, $step ) = @_;
    my $position = 0;
    return sub {
        my $substr = substr( $sequence, $position, $window_size );
        $position += $step;

        if ( length $substr == $window_size ) { return $substr }
    }
}

sub _score_boundries {
    my $seq = shift;
    my @boundries;
    for my $i (0 .. 6) {
        $boundries[0] += min( map { $score_of->{$_}[$i] } keys %$score_of );
        $boundries[1] += max( map { $score_of->{$_}[$i] } keys %$score_of );
    }

    $boundries[0] *= ( length($$seq) - 6 );
    $boundries[1] *= ( length($$seq) - 6 );

    return @boundries;

}

__PACKAGE__->meta->make_immutable;
__DATA__
---
A:
- '-6'
- '-2'
- '-4'
- '0'
- '-1'
- '0'
- '-12'
C:
- '2'
- '0'
- '2'
- '0'
- '0'
- '0'
- '0'
D:
- '-10'
- '-1'
- '-2'
- '0'
- '-2'
- '-1'
- '0'
E:
- '-3'
- '-2'
- '-9'
- '-6'
- '-1'
- '0'
- '0'
F:
- '4'
- '0'
- '4'
- '-1'
- '0'
- '1'
- '2'
G:
- '-2'
- '2'
- '1'
- '0'
- '0'
- '-2'
- '0'
H:
- '0'
- '-1'
- '0'
- '-1'
- '-1'
- '3'
- '-1'
I:
- '0'
- '0'
- '0'
- '-1'
- '4'
- '2'
- '-1'
K:
- '0'
- '-1'
- '0'
- '-6'
- '-8'
- '-1'
- '-6'
L:
- '1'
- '-1'
- '1'
- '1'
- '6'
- '5'
- '7'
M:
- '2'
- '2'
- '0'
- '0'
- '-1'
- '-2'
- '0'
N:
- '1'
- '1'
- '-6'
- '1'
- '0'
- '-1'
- '-7'
P:
- '1'
- '-6'
- '0'
- '2'
- '-6'
- '12'
- '-1'
Q:
- '0'
- '2'
- '2'
- '-2'
- '0'
- '1'
- '2'
R:
- '1'
- '-6'
- '2'
- '0'
- '1'
- '-2'
- '-2'
S:
- '-4'
- '-2'
- '2'
- '3'
- '-6'
- '-5'
- '-1'
T:
- '-2'
- '0'
- '-1'
- '-2'
- '-1'
- '1'
- '2'
V:
- '0'
- '1'
- '-2'
- '-2'
- '0'
- '-3'
- '-1'
W:
- '7'
- '6'
- '7'
- '4'
- '2'
- '2'
- '4'
Y:
- '-7'
- '-1'
- '-4'
- '3'
- '-5'
- '0'
- '1'

