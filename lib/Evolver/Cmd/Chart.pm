package Evolver::Cmd::Chart;
use Moose::Role;
use Chart::Gnuplot;
use MooseX::Getopt;
use namespace::autoclean;

use MooseX::Types::Moose qw(Bool);
use MooseX::Types::Path::Class qw(File);

has chartfile => (
   is  => 'ro',
   isa => File,
   predicate     => 'wants_chart',
   coerce        => 1,
   traits        => [qw(Getopt)],
   documentation => "Filename of the output chart",
);

after run => sub {

    my $self = shift;
    return unless $self->wants_chart;

    $self->chart( output => $self->chartfile );
    $self->e("Chart written at " . $self->chartfile . "\n");
};

1;
