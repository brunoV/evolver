package Evolver;
use Moose;
use MooseX::Types::Moose qw(Str Bool Num ArrayRef HashRef CodeRef);
use Evolver::Types qw(BioSimpleAlign Probability);
use AI::Genetic::Pro::Macromolecule;
use namespace::autoclean;
use List::Util qw(sum max min);

with 'Evolver::ProfileScoreI',
     'MooseX::Object::Pluggable',
     'Evolver::Chart::Gnuplot';

has fitness => (
    is  => 'ro',
    isa => CodeRef,
    required => 1,
);

has fitness_name => (
    is => 'ro',
    isa => Str,
);

has _actual_fitness => (
    is => 'ro',
    isa => CodeRef,
    lazy_build => 1,
);

has profile => (
   is       => 'ro',
   isa      => BioSimpleAlign,
   required => 1,
   coerce   => 1,
);

has profile_algorithm => (
   is      => 'ro',
   isa     => Str,
   default => 'Hmmer',
);

has inject => (
    is => 'ro',
    isa => ArrayRef[Str],
);

has inject_consensus => (
   is => 'ro',
   isa => Bool,
   default => 1,
);

has inject_profile_seqs => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'history_' . $_ => (
    is  => 'ro',
    isa => HashRef,
    traits => [qw(Hash)],
    default => sub { {} },
    handles => {
        '_add_history' . $_   => 'set',
        '_clear_history' . $_ => 'clear',
    },
) for qw(custom profile total);

sub fittest_seq {
    my ($self, $n) = @_;
    $n //= 1;

    my @fittest = map { $_->{seq} } $self->_gm->fittest($n);

    return ( $n == 1 ) ? $fittest[0] : @fittest;
}

sub fittest_score {
    my ($self, $n) = @_;
    $n //= 1;

    my @fittest;

    foreach my $seq_ref ($self->_gm->fittest($n)) {

        my $seq = $seq_ref->{seq};

        push @fittest, {
            total  => $seq_ref->{score},
            custom => $self->fitness->($seq),
        };
    }

    return ( $n == 1 ) ? $fittest[0] : @fittest;
}

sub fittest {
    my ($self, $n) = @_;
    $n //= 1;

    my @fittest;

    foreach my $seq_ref ($self->_gm->fittest($n)) {

        my $seq = $seq_ref->{seq};

        push @fittest, {
            seq   => $seq,
            score => {
                total  => $seq_ref->{score},
                custom => $self->fitness->($seq),
            }
        };
    }

    return ( $n == 1 ) ? $fittest[0] : @fittest;
}

sub _build__actual_fitness {
    my $self = shift;
    my $counter = 0;
    my $generation = 0;
    my @custom_scores;
    my @profile_scores;
    my @total_scores;;

    return sub {
        my $seq = shift;
        my $profile_score = $self->_profile_score->($seq);
        my $custom_score  = $self->fitness->($seq);
        my $final_score   = ( ( $profile_score**2 ) * ($custom_score) );

        # This is to avoid calling '->generation' when the GA object is
        # not properly initialized. Doing so causes an infinite
        # recursion, since it needs to compute the fitness with this sub
        # for the initial objects to initialize.
        unless ($counter > 1.4 * $self->population_size) {
            $counter++ and return $final_score
        }

        # When the generation number changes, calculate the stats and do
        # a cleanup of the gatherer arrays.
        if ( $generation < $self->generation ) {
            $generation++;

            # Calculate statistics
            push @{$self->history_custom->{min}},  min(@custom_scores);
            push @{$self->history_custom->{max}},  max(@custom_scores);
            push @{$self->history_custom->{mean}}, mean(@custom_scores);
            undef @custom_scores;

            push @{$self->history_profile->{min}},  min(@profile_scores);
            push @{$self->history_profile->{max}},  max(@profile_scores);
            push @{$self->history_profile->{mean}}, mean(@profile_scores);
            undef @profile_scores;

            push @{$self->history_total->{min}},  min(@total_scores);
            push @{$self->history_total->{max}},  max(@total_scores);
            push @{$self->history_total->{mean}}, mean(@total_scores);
            undef @total_scores;
        }

        push @custom_scores,  $custom_score;
        push @profile_scores, $profile_score;
        push @total_scores,   $final_score;

        return $final_score;
    }

}

my @params = qw(mutation crossover strategy parents selection
             preserve population_size terminate);

# I want to use the parameters above as attrs just like in AI::G::P::M, but
# without having to set them all over again, with the same default values.
# I'll delegate the getters and make new private attrs with the original
# name at build time (init_arg).

has '_' . $_ => (
    is => 'ro',
    init_arg  => $_,
) for @params;

has '_gm' => (
    is  => 'ro',
    isa => 'AI::Genetic::Pro::Macromolecule',
    lazy_build => 1,
    handles    => [qw(evolve generation history population_size
                   current_population current_stats), @params],
);

sub _build__gm {
    my $self = shift;

    my @mod_attrs  = grep { my $a = '_' . $_; defined $self->$a } @params;
    my %extra_args = map  { my $m = '_' . $_; $_ => $self->$m }   @mod_attrs;

    if ($self->inject_consensus) {
        push @{$extra_args{initial_population}}, $self->profile->consensus_string;
    }

    if ($self->inject_profile_seqs) {
        push @{$extra_args{initial_population}}, $self->_get_profile_seqs;
    }

    my $m = AI::Genetic::Pro::Macromolecule->new(
        type    => 'protein',
        fitness => $self->_actual_fitness,
        cache   => 1,
        length  => length( $self->profile->consensus_string ),
        %extra_args,
    );

    return $m;
}

sub BUILD {
    my $self = shift;

    $self->_load_profile_score_plugin;
}

sub _load_profile_score_plugin {
    # Load the appropiate ProfileScore role.

    my $self = shift;

   # We tell the plugin loader where to look for the plugin.
   #  App namespace..
   $self->_plugin_app_ns( ['Evolver'] );

   #  plugin namespace...
   $self->_plugin_ns('ProfileScore');

   #  plugin name.
   $self->load_plugin( $self->profile_algorithm );

   return 1;
}

sub mean { return sum(@_)/@_; }

sub _get_profile_seqs {
    my $self = shift;
    my @seqs = map { $_->seq } $self->profile->each_seq;

    s/[-.]//g for @seqs;

    return @seqs;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Evolver - Profile-constrained sequence optimization using
evolutionary algorithms.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

   use Evolver;

   my $evolver = Evolver->new(
      profile   => 'family.aln', # Bio::SimpleAlign, Bio::SeqIO, Bio::Seq, A filename with a sequences to be aligned.
      fitness   => \&fitness_function,
      terminate => \&terminate_function, #optional
   );

   $evolver->evolve(10)           # Evolve for ten generations.
   $evolver->chart('output.png')   # Plot a chart with the progress.

   my $seq = $evolver->getFittest. # Get a Bio::Seq object with the best fit.
   print $seq->seq;


=head1 DESCRIPTION

Evolver is an evolver...

=cut

=head1 Methods

=head2 Evolver->new(%args)

Constructor. Returns a Evolver object.
Accepts a hash with arguments, of which the fitness function
is the only mandatory.

    my $evolver = Evolver->new(
       fitness => \&fitness_function,
    );

Possible attributes include:

=over 8

=item fitness

This defines a I<fitness> function. It expects a reference to a subroutine.
Mandatory.
It is given a sequence string as an argument. It should return a numerical
value. This function is evaluated for each individual of the population.
Example:

   sub fitness {
      # This function tries to maximize the occurrence of residues
      # V, I, K and P.
      my $string = shift;
      my $count = grep { /[VIKP]/ } split '', $string;
      return $count/length($string);
   }

=item terminate

This defines a I<terminate> function. It expects a reference to a subroutine.
After each generation, the best individual of the population is passed to this
function as a Bio::Seq object, in which the attribute C<-seq> contains the
sequence, and the attribute C<-id> contains the overall score.
Example:

   sub terminate {
      # Evolution will stop when score reaches 0.3
      my $seq_obj = shift;
      return 1 if ($seq_obj->id > 0.3);
   }

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

    perldoc Evolver


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
