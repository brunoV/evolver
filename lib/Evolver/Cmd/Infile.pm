package Evolver::Cmd::Infile;
use Moose::Role;
use MooseX::Getopt;
use MooseX::Types::Moose qw(Str);
use namespace::autoclean;

has infile => (
    is  => 'ro',
    isa => Str,
    traits        => [qw(Getopt)],
    required      => 1,
    cmd_aliases   => 'i',
    documentation => "Filename with the family sequences or alignment",
);

1;
