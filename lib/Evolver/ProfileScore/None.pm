package Evolver::ProfileScore::None;
use Moose::Role;
requires '_build__profile_score';

# This ProfileScore role returns always a perfect score. It is used as a
# negative control for the profile-restricted part of the fitness
# function.

sub _build__min_score {
    return 0;
}

sub _build__max_score {
    return 1;
}

sub _score {
    return 1;
}

1;
