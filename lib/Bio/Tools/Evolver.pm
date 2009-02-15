package Bio::Tools::Evolver;

use Moose;
use AI::Genetic::Pro;

with 'Bio::Tools::Evolver::Profile';

=head1 NAME

Bio::Tools::Evolver - Profile-constrained sequence optimization using
evolutionary algorithms.

=head1 VERSION

Version 0.01

=cut

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

    my $evolver = Bio::Tools::Evolver->new;

=cut

our $VERSION = '0.01';

has '_root' => (
   is         => 'ro',
   isa        => 'Bio::Root::Root',
   lazy_build => 1,
   handles    => [qw(throw)],
);

has '_ga' => (
   is      => 'ro',
   writer  => '_set_ga',
   isa     => 'AI::Genetic::Pro',
   builder => '_build_ga',
   handles => [
      qw(terminate population crossover mutation parents selection
          strategy cache history preserve variable_length evolve
          chart)
   ],
);

sub _build_ga {
   my $self = shift;

   # Initialize the Genetic Algorithm engine with sane defaults.
   my $ga = AI::Genetic::Pro->new(
      -type            => 'listvector',       # type of chromosomes
      -population      => 300,                # population
      -crossover       => 0.95,               # probab. of crossover
      -mutation        => 0.01,               # probab. of mutation
      -parents         => 2,                  # number  of parents
      -selection       => ['Roulette'],       # selection strategy
      -strategy        => [ 'Points', 2 ],    # crossover strategy
      -cache           => 1,                  # cache results
      -history         => 1,                  # remember best results
      -preserve        => 5,                  # remember the bests
      -variable_length => 0,                  # turn variable length ON
   );

   $self->_set_ga($ga);
}

has 'fitness' => (
   is => 'ro',
   isa => 'CodeRef',
   required => 1,
);

=head2 getFittest

    Get the best scoring sequence after the evolution run
    . Returns a Bio::Seq object
    

    my $seq = $evolver->getFittest;
print $seq->seq;    # Print optimized sequence to screen.

=cut

sub getFittest {
   my $self = shift;

   # Get the fittest sequence as string, removing the artifacts that
   # it comes with.
   my $string = $self->_ga->as_string( $self->_ga->getFittest );
   $string =~ s/_//g;

   # Return a Bio::Seq object object with the optimized sequence.
   # TODO Think about a more informative id.
   my $fittest = Bio::Seq->new(
      -id  => 'fittest',    # Improve this?
      -seq => $string,
   );

   return $fittest;
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;    # End of Bio::Tools::Evolver
