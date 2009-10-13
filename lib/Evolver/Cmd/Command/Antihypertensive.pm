package Evolver::Cmd::Command::Antihypertensive;
use Moose;

extends 'Evolver::Cmd::Biopep';

use namespace::autoclean;

use MooseX::Types::Path::Class qw(File);

has '+activity' => ( default => 'antihypertensive' );

__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

Evolver::Cmd::Command::Antihypertensive - Increase the amount of encrypted antihypertensive peptides

=cut
