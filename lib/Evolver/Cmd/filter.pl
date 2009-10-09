#!/usr/bin/perl
use Modern::Perl;

my %amount_of;

while (<>) {
    my @fields = split "\t";
    my $activity = $fields[5];
    $activity =~ s/^\s+//;
    $activity =~ s/\s+$//;
    $amount_of{ $activity } += 1;
}

foreach my $act ( sort { $amount_of{$b} <=> $amount_of{$a} } keys %amount_of) {
    say $act, "\t", $amount_of{$act};
}
