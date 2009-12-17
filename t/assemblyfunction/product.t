use Test::More;

BEGIN {
    use_ok 'Evolver::AssemblyFunction::Product';
}

ok my $product = Evolver::AssemblyFunction::Product->new;

is $product->profile, 1;
is $product->custom,  1;

is $product->evaluate(2, 3), 6;

ok $product = Evolver::AssemblyFunction::Product->new(profile => 2, custom => 1);

is $product->profile, 2;
is $product->custom,  1;

is $product->evaluate(2, 3), 12;
is $product->evaluate(3, 2), 18;

done_testing();
