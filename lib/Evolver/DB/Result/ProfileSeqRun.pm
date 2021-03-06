package Evolver::DB::Result::ProfileSeqRun;

use strict;
use warnings;

use base 'Evolver::DB::Result';

__PACKAGE__->table("profile_seq_run");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "profile_seq_id",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "run_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "profile_seq",
  "Evolver::DB::Result::ProfileSeq",
  { id => "profile_seq_id" },
);
__PACKAGE__->belongs_to("run", "Evolver::DB::Result::Run", { id => "run_id" });


1;
