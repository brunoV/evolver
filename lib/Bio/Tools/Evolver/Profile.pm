package Bio::Tools::Evolver::Profile;
use strict;
use warnings;

use Moose::Role;
use Moose::Util::TypeConstraints;

=head1 NAME

Bio::Tools::Evolver::Profile - A role that gives a Profile attribute which
handles several ways to get an alignment.

=head1 SUMMARY

This role should provide a 'profile' attribute that accepts an alignment
filename, a Bio::AlignIO, Bio::SimpleAlign or Bio::SeqIO objects or an
arrayref of Bio::Seq objects. It then converts them into an alignment file,
so that the consumer of the role only has to deal with one datatype.  If the
user gives either a list of B:Seq objects or a B:SeqIO object, the role will
perform an alignment and save it in a temporary file.

=cut

=head1 SYNOPSIS

   package MyPackage;
   use Moose;
   with 'Bio::Tools::Evolver::Profile';

   ...

   package main;
   use MyPackage;
   my $foo = MyPackage->new(
      profile => $prof
   ); # $prof: filename, AlignIO, SimpleAlign, SeqIO, or Seq

   $foo->profile; # get the filename of the alignment.
=cut

has 'profile' => (
   is       => 'ro',
   isa      => 'BTE::Bio::SimpleAlign',
   required => 1,
   coerce   => 1,
);

=head1 AUTHOR

Bruno Vecchi, C<< <vecchi.b at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-tools-evolver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Tools-Evolver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Tools::Evolver::Profile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Tools-Evolver>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Tools-Evolver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Tools-Evolver>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Tools-Evolver/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Bruno Vecchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

no Moose;
1;
