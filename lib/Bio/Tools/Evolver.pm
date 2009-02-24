package Bio::Tools::Evolver;

use Moose;
use AI::Genetic::Pro;

with
    'Bio::Tools::Evolver::Types',
    'Bio::Tools::Evolver::Profile',
    'Bio::Tools::Evolver::ProfileScore';

my $prot_alph = 'ACDEFGHIKLMNPQRSTVWY';

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
   handles    => [ qw(evolve chart getHistory getAvgFitness generation) ],
);

has cache => (
   is      => 'rw',
   isa     => 'Bool',
   default => 1,
);

has mutation => (
   is      => 'rw',
   isa     => 'BTE::Probability',
   default => 0.01,
);

has crossover => (
   is      => 'rw',
   isa     => 'BTE::Probability',
   default => 0.95,
);

has population => (
   is      => 'rw',
   isa     => 'Num',
   default => 300,
);

has parents => (
   is      => 'rw',
   isa     => 'Num',
   default => 2,
);

has history => (
   is      => 'rw',
   isa     => 'Bool',
   default => 1,
);

has selection => (
   is      => 'rw',
   isa     => 'ArrayRef',
   default => sub { ['Roulette'] },
);

has strategy => (
   is      => 'rw',
   isa     => 'ArrayRef',
   default => sub { [ 'Points', 2 ] },
);

has preserve => (
   is      => 'rw',
   isa     => 'Num',
   default => '5',
);

has fitness => (
   is       => 'ro',
   isa      => 'CodeRef',
   required => 1,
);

has terminate => (
   is        => 'rw',
   isa       => 'CodeRef',
   predicate => '_has_terminate',
);

sub _build__ga {
   my $self = shift;

   # Initialize the Genetic Algorithm engine with sane defaults.
   my $ga = AI::Genetic::Pro->new(
      -type            => 'listvector',         # type of chromosomes
      -population      => $self->population,    # population size
      -mutation        => $self->mutation,      # mutation rate
      -crossover       => $self->crossover,     # crossover rate
      -parents         => $self->parents,       # number  of parents
      -selection       => $self->selection,     # selection strategy
      -strategy        => $self->strategy,      # crossover strategy
      -cache           => $self->cache,         # cache results
      -history         => $self->history,       # remember best results
      -preserve        => $self->preserve,      # remember the bests
      -variable_length => 0,                    # fixed length
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

   # if defined, create the terminate function
   if ( $self->_has_terminate ) {
      my $terminate = sub {
         my ($ga) = @_;
         my $seq = $ga->as_string( $ga->getFittest );
         $seq =~ s/_//g;

         return $self->terminate->($seq);
      };

      $self->_ga->terminate($terminate);
   }

}

before evolve => sub {
   my $self = shift;
   unless ( $self->_initialized ) { $self->_init }
};

has _initialized => (
   is      => 'rw',
   isa     => 'Bool',
   default => 0,
);

sub _init {
   my $self = shift;

   # Initialize the first generation.
   $self->_ga->init(
      [  map { [ split '', $prot_alph ] } ( 1 .. $self->profile->length )
      ]
   );
   $self->_initialized(1);
}

sub inject {
   my ( $self, @seq_objs ) = @_;
   unless (@seq_objs) {
      warn "No arguments given, didn't inject anything";
   }

   if ( grep { !$_->can('seq') } @seq_objs ) {
      $self->throw("Can only inject Bio::Seq objects");
   }

   if (
      grep { length $_ != $self->profile->length }
      map  { $_->seq } @seq_objs
       )
   {
      $self->throw(
         "Injected sequences must have
        the length of the alignment"
      );
   }

   $self->_init unless ( $self->_initialized );

   my @seqs = map { [ split '', $_->seq ] } @seq_objs;
   $self->_ga->inject( \@seqs );

}

sub getFittest {
   my ( $self, $amount, $is_unique ) = @_;
   $amount ||= 1;
   my @fittest_ind = $self->_ga->getFittest( $amount, $is_unique );
   my @strings = map { $self->_ga->as_string($_) } @fittest_ind;
   my @scores  = map { $self->_ga->as_value($_) } @fittest_ind;

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

=head1 NAME

Bio::Tools::Evolver - Profile-constrained sequence optimization using
evolutionary algorithms.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

   use Bio::Tools::Evolver;

   my $evolver = Bio::Tools::Evolver->new(
      profile   => 'family.aln', # Bio::SimpleAlign, Bio::SeqIO, Bio::Seq, A filename with a sequences to be aligned.
      fitness   => \&fitness_function,
      terminate => \&terminate_function, #optional
   );

   $evolver->evolver(10)           # Evolve for ten generations.
   $evolver->chart('output.png')   # Plot a chart with the progress.

   my $seq = $evolver->getFittest. # Get a Bio::Seq object with the best fit.
   print $seq->seq;


=head1 DESCRIPTION

Bio::Tools::Evolver is an evolver...

=cut

=head1 Methods

=cut

=head2 Bio::Tools::Evolver->new(%args)

Constructor. Returns a Bio::Tools::Evolver object.
Accepts a hash with arguments, of which the fitness function
is the only mandatory.

    my $evolver = Bio::Tools::Evolver->new(
       fitness => \&fitness_function,
    );

Possible attributes include:

=over 8

=item fitness

This defines a I<fitness> function. It expects a reference to a subroutine.
Mandatory.

=item terminate

This defines a I<terminate> function. It expects a reference to a subroutine.
A sequence string is passed as an argument, and the current run will be
terminated if it returns true.

=item population

This defines the size of the population, i.e. how many sequences to
simultaneously exist at each generation.

=item crossover

This defines the crossover rate. Defaults to I<0.95>.

=item mutation

This defines the mutation rate. Defaults to I<0.01>.

=item preserve

This defines injection of the best sequences into a next generation.  It causes
a little slow down, however (very often) much better results are achieved. You
can specify, how many chromosomes will be preserved, i.e.

    preserve => 1, # only one sequence will be preserved
    # or
    preserve => 9, # 9 sequence will be preserved
    # and so on...

Attention! You cannot preserve more sequences than your population consists.

=item parents

This defines how many parents should be used in a crossover. Defaults to I<2>.

=item selection

This defines how individuals/chromosomes are selected to crossover. It expects
an array reference listed below:

    selection => [ $type, @params ]

where type is one of:

=over 8

=item B<RouletteBasic>

=item B<Roulette> (default)

=item B<RouletteDistribution>

=over 12

=item C<-selection =E<gt> [ 'RouletteDistribution', 'uniform' ]>

=item C<-selection =E<gt> [ 'RouletteDistribution', 'normal', $av, $sd ]>

=item C<-selection =E<gt> [ 'RouletteDistribution', 'beta', $aa, $bb ]>

=item C<-selection =E<gt> [ 'RouletteDistribution', 'binomial' ]>

=item C<-selection =E<gt> [ 'RouletteDistribution', 'chi_square', $df ]>

=item C<-selection =E<gt> [ 'RouletteDistribution', 'exponential', $av ]>

=item C<-selection =E<gt> [ 'RouletteDistribution', 'poisson', $mu ]>

=back

=item B<Distribution>

=over 12

=item C<-selection =E<gt> [ 'Distribution', 'uniform' ]>

=item C<-selection =E<gt> [ 'Distribution', 'normal', $av, $sd ]>

=item C<-selection =E<gt> [ 'Distribution', 'beta', $aa, $bb ]>

=item C<-selection =E<gt> [ 'Distribution', 'binomial' ]>

=item C<-selection =E<gt> [ 'Distribution', 'chi_square', $df ]>

=item C<-selection =E<gt> [ 'Distribution', 'exponential', $av ]>

=item C<-selection =E<gt> [ 'Distribution', 'poisson', $mu ]>

=back

=back

For more information on these selection parameters, refer to the original
L<AI::Genetic::Pro> documentation, from which this module inherits from.

=item strategy

This defines strategy of crossover operation. It expects an array reference listed below:

    strategy => [ $type, @params ]

where type is one of:

=over 4

=item PointsSimple

    strategy => [ 'PointsSimple', $n ]

=item PointsBasic

    strategy => [ 'PointsBasic', $n ]

=item Points (default, with 2 points)

Crossover in one or many points. In normal crossover selected parents are crossed and the best of child is moved to new generation. In example:

    strategy => [ 'Points', $n ]

where C<$n> is number of points for crossing.

=item PointsAdvanced

    strategy => [ 'PointsAdvanced', $n ]

=item Distribution

In I<distribution> crossover parents are crossed in points selected with specified distribution. See below.

=over 8

=item C<strategy =E<gt> [ 'Distribution', 'uniform' ]>

=item C<strategy =E<gt> [ 'Distribution', 'normal', $av, $sd ]>

=item C<strategy =E<gt> [ 'Distribution', 'beta', $aa, $bb ]>

=item C<strategy =E<gt> [ 'Distribution', 'binomial' ]>

=item C<strategy =E<gt> [ 'Distribution', 'chi_square', $df ]>

=item C<strategy =E<gt> [ 'Distribution', 'exponential', $av ]>

=item C<strategy =E<gt> [ 'Distribution', 'poisson', $mu ]>

=back

=item PMX

=item OX

=back

For more information on these strategy parameters, refer to the original
L<AI::Genetic::Pro> documentation, from which this module inherits from.

=item cache

This defines if cache should be used. Correct values are: 1 or 0 (default: I<0>).

=item history

This defines if history should be collected. Correct values are: 1 or 0 (default: I<0>).

Collect history.

=back

=cut

=head2 inject(@seqs)

Inject user-defined sequences in the current population. Accepts a list
of Bio::Seq objects.

    my $seq = Bio::Seq->new(-seq => $consensus_string);
    $ev->inject($seq);

=cut

=head2 evolve($n)

This method evolves the population for the specified
number of generations. If its argument is 0 or C<undef>, evolution will
take place indefinitely or until the terminate function returns true.

=cut

=head2 getFittest($n, $unique)

    Get the $n best scoring sequences after the evolution run.
    In scalar context, returns a Bio::Seq object, corresponding
    to the best sequence. In list context, returns a list of Bio::Seq
    objects of a size equal to the first argument given. Sequence scores
    are stored in the C<-id> attribute of each sequence retrieved.

    my $seq  = $evolver->getFittest;      # get best sequence.
    my @seqs = $evolver->getFittest(5)    # get the best 5 sequences.
    my @seqs = $evolver->getFittest(5, 1) # Assure uniqueness

    my $best_score = $seq->id;            # The score is stored in the id.

=cut

=head2 getAvgFitness

Get I<max>, I<mean> and I<min> score of the current generation. In example:

    my ($max, $mean, $min) = $ga->getAvgFitness();

=cut

=head2 getHistory

Get history of the evolution. It is in a format listed below:

	[
		# gen0   gen1   gen2   ...          # generations
		[ max0,  max1,  max2,  ... ],       # max values
		[ mean,  mean1, mean2, ... ],       # mean values
		[ min0,  min1,  min2,  ... ],       # min values
	]

=cut

=head2 generation

Get number of generation.

=cut

=head2 chart(%options)

Generate a chart describing changes of min, mean, max scores in Your
population. You can pass the following options:

=over 4

=item -filename

File to save a chart in (B<mandatory>).

=item -title

Title of a chart (default: I<Evolution>).

=item -x_label

X label (default: I<Generations>).

=item -y_label

Y label (default: I<Value>).

=item -format

Format of values, like C<sprintf> (default: I<'%.2f'>).

=item -legend1

Description of min line (default: I<Min value>).

=item -legend2

Description of min line (default: I<Mean value>).

=item -legend3

Description of min line (default: I<Max value>).

=item -width

Width of a chart (default: I<640>).

=item -height

Height of a chart (default: I<480>).

=item -font

Path to font in (*.ttf format) to be used (default: none).

=item -logo

Path to logo (png/jpg image) to embed in a chart (default: none).

=item In example:

	$ga->chart(-width => 480, height => 320, -filename => 'chart.png');

=back

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
