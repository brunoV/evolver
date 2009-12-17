package Evolver::DB::Result::Run;

use strict;
use warnings;
use CLASS;

use base 'Evolver::DB::Result';

CLASS->table("run");
CLASS->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "fitness_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "assembly_function_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "profile_algorithm",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "inject_consensus",
  {
    data_type => "boolean",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "mutation",
  {
    data_type => "float",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "crossover",
  {
    data_type => "float",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "strategy",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "parents",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "selection",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "preserve",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "population_size",
  {
    data_type => "INTEGER",
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
  "history",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "description",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
CLASS->set_primary_key("id");
CLASS->belongs_to("fitness", "Evolver::DB::Result::Fitness", { id => "fitness_id" });
CLASS->belongs_to("assembly_function", "Evolver::DB::Result::AssemblyFunction", { id => "assembly_function_id" });
CLASS->has_many(
  "profile_seq_runs",
  "Evolver::DB::Result::ProfileSeqRun",
  { "foreign.run_id" => "self.id" },
);
CLASS->has_many(
  "optimized_seqs",
  "Evolver::DB::Result::OptimizedSeq",
  { "foreign.run_id" => "self.id" },
);


CLASS->many_to_many('profile_seqs', 'profile_seq_runs', 'profile_seq');

1;
