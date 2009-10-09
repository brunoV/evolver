package Evolver::Cmd::Chart;
use Moose::Role;
use Chart::Gnuplot;
use MooseX::Getopt;
use namespace::autoclean;

use MooseX::Types::Moose qw(Bool);
use MooseX::Types::Path::Class qw(File);

has plot => (
    is  => 'ro',
    isa => Bool,
    traits        => [qw(Getopt)],
    default       => 1,
    documentation => "Plot fitness evolution",
);

has chartfile => (
   is  => 'ro',
   isa => File,
   default       => "outchart.eps",
   coerce        => 1,
   traits        => [qw(Getopt)],
   documentation => "Filename of the output chart",
);

after run => sub {

    my $self = shift;

    $self->chart( output => $self->chartfile );
    $self->e("Chart written at " . $self->chartfile . "\n");
};

1;
