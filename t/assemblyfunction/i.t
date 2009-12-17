use Test::More;
use Modern::Perl;

{
    package Foo;
    use Moose;
    with 'Evolver::AssemblyFunctionI';

    sub evaluate { 42 };

    sub name { 'foo42' };
}

my $foo = Foo->new;

ok $foo->does('Evolver::AssemblyFunctionI');

is $foo->evaluate, 42;

is $foo->name, 'foo42';

done_testing;
