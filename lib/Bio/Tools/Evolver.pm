package Bio::Tools::Evolver;

use Moose;
use AI::Genetic::Pro;

with 'Bio::Tools::Evolver::Types', 'Bio::Tools::Evolver::Profile',
    'Bio::Tools::Evolver::ProfileScore';

my $prot_alph = 'ACDEFGHIKLMNPQRSTVWY';

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
   );

   $evolver->evolver(10) # Evolve for ten generations.
   $evolver->graph('output.png')

   my $seq = $evolver->getFittest. # Get a Bio::Seq object with the best fit.
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

has _root => (
   is         => 'ro',
   isa        => 'Bio::Root::Root',
   init_arg   => undef,
   lazy_build => 1,
   handles    => [qw(throw)],
);

has _ga => (
   is         => 'ro',
   writer     => '_set_ga',
   isa        => 'AI::Genetic::Pro',
   init_arg   => undef,
   lazy_build => 1,
   handles    => [
      qw(terminate evolve chart as_value getHistory
          getAvgFitness generation getFittest_as_arrayref
          people chromosomes)
   ],
);

has 'cache' => (
   is      => 'rw',
   isa     => 'Bool',
   default => 1,
);

has 'mutation' => (
   is      => 'rw',
   isa     => 'BTE.Probability',
   default => 0.01,
);

has 'crossover' => (
   is      => 'rw',
   isa     => 'BTE.Probability',
   default => 0.95,
);

has 'population' => (
   is      => 'rw',
   isa     => 'Num',
   default => 300,
);

has 'parents' => (
   is      => 'rw',
   isa     => 'Num',
   default => 2,
);

has 'history' => (
   is      => 'rw',
   isa     => 'Bool',
   default => 1,
);

has 'selection' => (
   is      => 'rw',
   isa     => 'ArrayRef',
   default => sub { ['Roulette'] },
);

has 'strategy' => (
   is      => 'rw',
   isa     => 'ArrayRef',
   default => sub { [ 'Points', 2 ] },
);

has 'preserve' => (
   is      => 'rw',
   isa     => 'Num',
   default => '5',
);

has 'fitness' => (
   is       => 'ro',
   isa      => 'CodeRef',
   required => 1,
);

sub _build__ga {
   my $self = shift;

   # Initialize the Genetic Algorithm engine with sane defaults.
   my $ga = AI::Genetic::Pro->new(
      -type       => 'listvector',        # type of chromosomes
      -population => $self->population,   # population size
      -mutation   => $self->mutation,     # mutation rate
      -crossover  => $self->crossover,    # crossover rate
      -parents    => $self->parents,      # number  of parents
      -selection  => $self->selection,    # selection strategy
      -strategy   => $self->strategy,     # crossover strategy
      -cache      => $self->cache,        # cache results
      -history    => $self->history,      # remember best results
      -preserve   => $self->preserve,     # remember the bests
      -variable_length => 0,              # fixed length
   );
   return $ga;
}

sub BUILD {
   my $self = shift;

   # Create the fitness function, which is composed of the
   # ProfileScore function and the user function.
   my $fitness = sub {
      my ( $ga, $chromosome ) = @_;
      my $seq = $ga->as_string($chromosome);
      $seq =~ s/_//g;
      my $profile_score = $self->_my_fitness->($seq);
      my $custom_score  = $self->fitness->($seq);
      my $final_score   = ( ( $profile_score**2 ) * ($custom_score) );
      return $final_score;
   };
   $self->_ga->fitness($fitness);
}

before 'evolve' => sub {
   my $self = shift;
   unless ($self->_initialized) { $self->_init };
};

has _initialized => (
   is      => 'rw',
   isa     => 'Bool',
   default => 0,
);


sub _init {
   my $self = shift;

   # Initialize the first generation.
   $self->_ga->init([
      map { [ split '', $prot_alph ] } ( 1 .. $self->profile->length )
   ]);
   $self->_initialized(1);
}

sub inject {
   my ($self, @seq_objs) = @_;
   unless (@seq_objs) { warn "No arguments given, didn't inject anything" };

   if (grep { !$_->can('seq') } @seq_objs) {
      $self->throw("Can only inject Bio::Seq objects");
   }

   if (
      grep { length $_ != $self->profile->length }
      map { $_->seq } @seq_objs
   )
   {
     $self->throw("Injected sequences must have
        the length of the alignment");
   }

   $self->_init unless ($self->_initialized);

   my @seqs = map { [ split '', $_->seq ] } @seq_objs;
   $self->_ga->inject(\@seqs);

}

=head2 getFittest

    Get the best scoring sequence after the evolution run
    . Returns a Bio::Seq object
    

    my $seq = $evolver->getFittest;
print $seq->seq;    # Print optimized sequence to screen.

=cut

sub getFittest {
   my ( $self, $amount, $is_unique ) = @_;
   $amount ||= 1;
   my @fittest_ind = $self->_ga->getFittest( $amount, $is_unique );
   my @strings = map { $self->_ga->as_string($_) } @fittest_ind;
   my @scores  = map { $self->_ga->as_value ($_) } @fittest_ind;

   my @fittest_seq;
   foreach my $i ( 0 .. $#strings ) {

      # Get the fittest sequence as string, removing the artifacts that
      # it comes with.
      $strings[$i] =~ s/_//g;

      # Return a Bio::Seq object object with the optimized sequence.
      my $fittest = Bio::Seq->new(
         -id  => $scores[$i],
         -seq => $strings[$i],
      );
      push @fittest_seq, $fittest;
   }

   return wantarray ? @fittest_seq : $fittest_seq[0];
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
