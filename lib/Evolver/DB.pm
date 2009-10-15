package Evolver::DB;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-15 16:56:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RVuaFIggNclOIizt5h/TKw


# You can replace this text with custom content, and it will be preserved on regeneration

use YAML;

sub insert_evolver {
    my ( $self, $e ) = @_;

    unless ( $e->isa("Evolver") ) { die "Not an Evolver object" }

     $self->txn_do(sub { # Data integrity is good m'kay?

        my $fitness        = $self->insert_function($e);

        my $run = $self->resultset('Run')->update_or_create({

            strategy     => Dump($e->strategy),
            selection    => Dump($e->selection),
            history      => Dump({
                custom  => $e->history_custom,
                profile => $e->history_profile,
                total   => $e->history_total,
            }),

            profile_algorithm => $e->profile_algorithm,
            inject_consensus  => $e->inject_consensus,
            mutation          => $e->mutation,
            crossover         => $e->crossover,
            parents           => $e->parents,
            preserve          => $e->preserve,
            population_size   => $e->population_size,
            generation        => $e->generation,

            fitness_id     => $fitness->id,

        });

        $self->add_profile_seqs_to_run($e, $run);

        return $run;

    });
}

sub add_optimized_seq_to_run {
    my ($self, $run, $opt_seq) = @_;

    unless (
        $self->isa('Evolver::DB')      &&
        $run ->isa('Evolver::DB::Run') &&
        ref $opt_seq eq 'HASH'
    ) { die "need proper arguments\n" }

    my $seq = delete $opt_seq->{seq};

    my $seq_rs = $self->resultset('ResultSeq')->find_or_create(
        { seq => $seq, type => 'protein' }, { key => 'seq_unique' }
    );

    return $seq_rs->add_to_optimized_seqs({
        %$opt_seq, run_id => $run->id
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

sub add_profile_seqs_to_run {
    my ($self, $e, $run) = @_;

    unless (
        $self->isa('Evolver::DB') &&
        $e   ->isa('Evolver')     &&
        $run ->isa('Evolver::DB::Run')
    ) { die "need proper arguments\n" }

    # Here I use update_or_create: it searches using primary key or
    # unique constraint (in this case, seq). If found, it then updates
    # with the information on the extra columns. If not, creates the
    # row.
    foreach my $profile ( $self->profile_seqs($e) ) {
        my $profile_seq_rs =
            $self->resultset('ProfileSeq')->update_or_create($profile);

        $run->add_to_profile_seqs($profile_seq_rs);
    }
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

    return @profile_seqs;
}

sub optimized_seqs {
    my ($self, $e, $n) = @_;
    $n //= 1;

    my @optimized_seqs;

    foreach my $seq_ref ($e->fittest($n)) {
        push @optimized_seqs,
            {
                seq          => $seq_ref->{seq},
                custom_score => $seq_ref->{score}->{custom},
                total_score  => $seq_ref->{score}->{total},
                generation   => $e->generation,
            };
    }

    return ($n == 1) ? $optimized_seqs[0] : @optimized_seqs;
}

1;
