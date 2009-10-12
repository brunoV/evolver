package Evolver::DB;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-11 20:50:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lH5s4adBWcWx3EoLi/USOQ


# You can replace this text with custom content, and it will be preserved on regeneration

use YAML;

sub insert_evolver {
    my ( $self, $e ) = @_;

    unless ( $e->isa("Evolver") ) { die "Not an Evolver object" }

     $self->txn_do(sub { # Data integrity is good m'kay?

        my $fitness        = $self->insert_function($e);
        my $profile_seqs   = $self->insert_profile_seqs($e);

        my $run = $fitness->add_to_runs({
            strategy     => Dump($e->strategy),
            selection    => Dump($e->selection),
            history      => Dump($e->history),

            profile_algorithm => $e->profile_algorithm,
            inject_consensus  => $e->inject_consensus,
            mutation          => $e->mutation,
            crossover         => $e->crossover,
            parents           => $e->parents,
            preserve          => $e->preserve,
            population_size   => $e->population_size,
            generation        => $e->generation,

            optimized_seqs => $self->optimized_seqs($e),

        });

        $run->add_to_profile_seqs($_) for @$profile_seqs;

        return $run;

    });
}

sub insert_function {
    my ($self, $e) = @_;

    # Since fitness.name is a unique constraint, and we are not adding
    # any extra information, we use 'find_or_create', since 'find'
    # searches by primary key or unique constraint only.
    my $fitness_rs = $self->resultset('Fitness')->find_or_create(
        { name => $e->fitness_name }
    );

    return $fitness_rs;
}

sub insert_profile_seqs {
    my ($self, $e) = @_;

    # Here I use update_or_create: it searches using primary key or
    # unique constraint (in this case, seq). If found, it then updates
    # with the information on the extra columns. If not, creates the
    # row.
    my @profile_seq_rs;
    foreach my $seq_obj ($e->profile->each_seq) {

        # remove alignment info from the string, since we only care
        # about the sequence itself
        my $seqstr = $seq_obj->seq;
        $seqstr =~ s/-//g;

        push @profile_seq_rs,
            $self->resultset('ProfileSeq')->update_or_create({
                id   => $seq_obj->id,
                type => 'protein',
                seq  => $seqstr,
            });
    }

    return \@profile_seq_rs;
}

sub profile_seqs {
    my ($self, $e) = @_;

    my @profile_seqs;
    foreach my $seq_obj ($e->profile->each_seq) {

        # remove alignment info from the string, since we only care
        # about the sequence itself
        my $seqstr = $seq_obj->seq;
        $seqstr =~ s/-//g;

        push @profile_seqs,
            {
                id   => $seq_obj->id,
                seq  => $seqstr,
                type => 'protein',
            };
    }

    return \@profile_seqs;
}

sub insert_optimized_seqs {
    my ($self, $e, $run_id, $n) = @_;
    $n //= ($e->population_size < 10) ? $e->population_size : 10;
    $run_id // die " need a run_id ";

    my @optimized_seq_rs;

    foreach my $seq_ref ($e->fittest($n)) {
        push @optimized_seq_rs,
            $self->resultset('OptimizedSeq')->create({
                seq          => $seq_ref->{seq},
                type         => 'protein',
                custom_score => $seq_ref->{score}->{custom},
                total_score  => $seq_ref->{score}->{total},
                run_id       => $run_id,
            });
    }

    return \@optimized_seq_rs;

}

sub optimized_seqs {
    my ($self, $e, $n) = @_;
    $n //= ($e->population_size < 10) ? $e->population_size : 10;

    my @optimized_seqs;

    foreach my $seq_ref ($e->fittest($n)) {
        push @optimized_seqs,
            {
                seq          => $seq_ref->{seq},
                custom_score => $seq_ref->{score}->{custom},
                total_score  => $seq_ref->{score}->{total},
                type         => 'protein',
            };
    }

    return \@optimized_seqs;
}

1;
