use strict;
use warnings;
use ExtUtils::MakeMaker;

my $v = 1.006900;
eval "use Bio::Root::Build $v";
if ($@) {
    # using die so wrappers can catch the error message    
    die "BioPerl minimal core version $v is required";
}

eval "use Bio::Tools::Run::Alignment::Clustalw $v";
if ($@) {
    # using die so wrappers can catch the error message    
    die "BioPerl-run minimal core version $v is required";
}

WriteMakefile(
    NAME                => 'Bio::Tools::Evolver',
    AUTHOR              => 'Bruno Vecchi <vecchi.b@gmail.com>',
    VERSION_FROM        => 'lib/Bio/Tools/Evolver.pm',
    ABSTRACT_FROM       => 'lib/Bio/Tools/Evolver.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'AI::Genetic::Pro'           => 0,
        'Algorithm::NeedlemanWunsch' => 0,
        'Moose'                      => 0.72,
        'MooseX::Object::Pluggable'  => 0,
        'Memoize'                    => 0,
        'File::Basename'             => 0,
        'List::MoreUtils'            => 0,
        'File::Temp'                 => 0,
        'Test::More'                 => 0,
        'Test::Exception'            => 0,
        'Test::Warn'                 => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-Tools-Evolver-*' },
);
