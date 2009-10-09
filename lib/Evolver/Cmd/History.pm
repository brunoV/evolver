package Evolver::Cmd::History;
use Moose::Role;
use namespace::autoclean;
use MooseX::Types::Path::Class qw(File);

use MooseX::Types::Moose qw(Str Undef);

has historyfile => (
    is  => 'ro',
    isa => File,
    traits    => [qw(Getopt)],
    predicate => 'wants_history',
    coerce    => 1,
);

after run => sub {
   my $self = shift;

   if ($self->wants_history) {

       $self->write_history;
       $self->e("History written in " . $self->historyfile . "\n");
    }

};

sub write_history {
    my $self = shift;

    my $history = $self->history;

    my ($max, $min) = ($history->{max}, $history->{min});

    my $fh = $self->historyfile->openw();

    foreach my $gen (1 .. @$max + 1) {
       $fh->print(
           $gen,             "\t",
           $max->[$gen - 1], "\t",
           $min->[$gen - 1], "\n"
       );
    }
}

1;
