package Evolver::DB::Result::OptimizedSeq;

use strict;
use warnings;
use CLASS;

use base 'Evolver::DB::Result';

CLASS->table("optimized_seq");
CLASS->add_columns(
  "id",
  {
    data_type => "INTEGER",
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
  "seq_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "custom_score",
  {
    data_type => "float",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "total_score",
  {
    data_type => "float",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "generation",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "name",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
CLASS->set_primary_key("id");
CLASS->belongs_to("run", "Evolver::DB::Result::Run", { id => "run_id" });
CLASS->belongs_to("seq", "Evolver::DB::Result::ResultSeq", { id => "seq_id" });


1;
