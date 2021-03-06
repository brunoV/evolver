package Evolver::DB;

use strict;
use warnings;
use CLASS;
use YAML;

use base 'DBIx::Class::Schema';


CLASS->load_namespaces(
    default_resultset_class => 'ResultSet',
);


sub insert_evolver {
    my ( $self, $e ) = @_;

    unless ( $e->isa("Evolver") ) { die "Not an Evolver object" }

     $self->txn_do(sub { # Data integrity is good m'kay?

        my $fitness        = $self->insert_fitness_function ($e);
        my $assembly       = $self->insert_assembly_function($e);

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

            fitness_id           => $fitness->id,
            assembly_function_id => $assembly->id,

        });

        $self->add_profile_seqs_to_run($e, $run);

        return $run;

    });
}

sub add_optimized_seq_to_run {
    my ($self, $run, $opt_seq) = @_;

    unless (
        $self->isa('Evolver::DB')              &&
        $run ->isa('Evolver::DB::Result::Run') &&
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

sub insert_fitness_function {
    my ($self, $e) = @_;

    # Since fitness.name is a unique constraint, and we are not adding
    # any extra information, we use 'find_or_create', since 'find'
    # searches by primary key or unique constraint only.
    my $fitness_rs = $self->resultset('Fitness')->find_or_create(
        { name => $e->fitness_name }
    );

    return $fitness_rs;
}

sub insert_assembly_function {
    my ($self, $e) = @_;

    # Since assembly_function.name is a unique constraint, and we are not adding
    # any extra information, we use 'find_or_create', since 'find'
    # searches by primary key or unique constraint only.
    my $assembly_rs = $self->resultset('AssemblyFunction')->find_or_create(
        { name => $e->assembly_function->name }
    );

    return $assembly_rs;
}

sub add_profile_seqs_to_run {
    my ($self, $e, $run) = @_;

    unless (
        $self->isa('Evolver::DB') &&
        $e   ->isa('Evolver')     &&
        $run ->isa('Evolver::DB::Result::Run')
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
