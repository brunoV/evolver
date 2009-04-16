package Bio::Tools::Evolver::Chart::Gnuplot;
use Moose::Role;
use Chart::Gnuplot;

sub chart {
    my ($self, $args) = @_;

    my $generations = scalar @{$self->getHistory->[0]};
    my $max_scores = \@{$self->getHistory->[0]};
    my $min_scores = \@{$self->getHistory->[1]};

    my $chart = Chart::Gnuplot->new(
        output => $args->{output} // "plot.eps",
        title  => $args->{title}  // "Evolution",
        xlabel => $args->{xlabel} // "Generations",
        ylabel => $args->{ylabel} // "Fitness Score"
    );

    # Create dataset object and specify the properties of the dataset
    my $max = Chart::Gnuplot::DataSet->new(
        xdata => [ 1 .. $generations ],
        ydata => $max_scores,
        title => "Max value",
        style => "linespoints",
    );

    my $min = Chart::Gnuplot::DataSet->new(
        xdata => [ 1 .. $generations ],
        ydata => $min_scores,
        title => "Min value",
        style => "linespoints",
    );

    # Plot the data sets on the chart
    $chart->plot2d($max, $min);
}

1;
