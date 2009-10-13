package Evolver::Cmd::DB;
use Moose::Role;
use MooseX::Getopt;
use namespace::autoclean;

use MooseX::Types::Moose qw(Str ArrayRef HashRef);
use Evolver::DB;

has dbfile => (
    is  => 'ro',
    isa => Str,
    traits    => [qw(Getopt)],
    predicate => 'wants_db',
    documentation => 'New or existent SQLite file to which to store all the results',
);

has _db => (
    is  => 'ro',
    isa => 'Evolver::DB',
    traits     => [qw(NoGetopt)],
    handles    => [qw(connect)],
    lazy_build => 1,
);

has _fittest_for_db => (
    is  => 'ro',
    isa => ArrayRef[HashRef],
    default => sub { [] },
    traits  => [qw(Array)],
    handles => {
        _add_fittest   => 'push',
        _clear_fittest => 'clear',
    }
);

sub _build__db {
    my $self = shift;

    my $db = Evolver::DB->connect('dbi:SQLite:dbname=' . $self->dbfile);
    unless (-e $self->dbfile) { $db->deploy }

    return $db;
}

sub _get_fittest_for_db {
    my ($self, $n) = @_;
    $n //= 1;

    $self->_db->optimized_seqs($self->evolver, $n);
}

sub _save_to_db {
    my $self = shift;

    # Save the Evolver, Fitness and ProfileSeqs first
    my $run = $self->_db->insert_evolver($self->evolver);

    # Then add the optimized seqs collected in the evolution to the
    # added Run
    $run->add_to_optimized_seqs($_) for @{$self->_fittest_for_db}

}

after evolve_once => sub {
    my $self = shift;

    # Collect the fittest sequence after each generation
    return unless ($self->wants_db);

    $self->_add_fittest( $self->_get_fittest_for_db );

};

after run => sub {
    my $self = shift;

    return unless ($self->wants_db);

    # Save the evolver run along with the top sequence for each
    # generation in the database
    $self->_save_to_db;
};

1;
