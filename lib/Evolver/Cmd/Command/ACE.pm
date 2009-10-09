package Evolver::Cmd::Command::ACE;
use Moose;

extends 'Evolver::Cmd::Biopep';

use namespace::autoclean;

use MooseX::Types::Path::Class qw(File);

has '+activity' => ( default => 'antihypertensive' );

__PACKAGE__->meta->make_immutable;
