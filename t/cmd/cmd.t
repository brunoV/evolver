use Test::More;
use App::Cmd::Tester;
use Evolver::Cmd;

my $result = test_app('Evolver::Cmd' => [ qw() ]);

TODO: {
    local $TODO = 'nose';

    like($result->stdout, qr/available/i, 'printed what we expected');

    is($result->stderr, '', 'nothing sent to sderr');
}

# is($result->error, undef, 'threw no exceptions');
# 
# my $result = test_app(YourApp => [ qw(command --opt value --quiet) ]);
# 
# is($result->output, '', 'absolutely no output with --quiet');

ok 1;

done_testing;
