package Evolver::DB::Result::ProfileSeq;

use strict;
use warnings;

use base 'Evolver::DB::Result';

__PACKAGE__->table("profile_seq");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "type",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "seq",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("seq_unique", ["seq"]);
__PACKAGE__->has_many(
  "profile_seq_runs",
  "Evolver::DB::Result::ProfileSeqRun",
  { "foreign.profile_seq_id" => "self.id" },
);


__PACKAGE__->many_to_many('runs', 'profile_seq_runs', 'run');

1;
