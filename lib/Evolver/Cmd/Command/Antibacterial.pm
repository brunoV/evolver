package Evolver::Cmd::Command::Antibacterial;
use Moose;

use lib qw(/home/brunov/lib/bio-tools-evolver/lib);
use lib qw(/home/brunov/lib/bio-tools-evolver-app/lib);

extends 'Evolver::Cmd::Biopep';

use namespace::autoclean;

use MooseX::Types::Path::Class qw(File);

has '+activity' => ( default => 'antibacterial' );

__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

Evolver::Cmd::Command::Antibacterial - Increase the amount of encrypted antibacterial peptides

=cut
