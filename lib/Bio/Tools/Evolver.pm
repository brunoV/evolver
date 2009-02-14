package Bio::Tools::Evolver;

use Moose;
extends 'Moose::Object', 'Bio::Root::Root';

=head1 NAME

Bio::Tools::Evolver - Profile-constrained sequence optimization using
evolutionary algorithms.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Bio::Tools::Evolver;

    my $evolver = Bio::Tools::Evolver->new(
      profile => 'family.aln', # Bio::SimpleAlign, Bio::SeqIO, Bio::Seq, A filename with a sequences to be aligned.
      fitness => \&fitness_function,
      terminate => \&terminate_function, #optional
      alphabet => 'protein' #optional, should be able to be guessed
   );

   $evolver->evolver(10) # Evolve for ten generations.
   $evolver->graph('output.png')

   my $seq = $evolver->getFitest. # Get a Bio::Seq object with the best fit.
   print $seq->seq;

   

=head1 DESCRIPTION

Bio::Tools::Evolver is an evolver...

=head1 Methods

=head2 Bio::Tools::Evolver->new(%args)
   Constructor. Returns a Bio::Tools::Evolver object.
   Accepts a hash with arguments.

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Bruno Vecchi, C<< <vecchi.b at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-tools-evolver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Tools-Evolver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Tools::Evolver


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

1; # End of Bio::Tools::Evolver
