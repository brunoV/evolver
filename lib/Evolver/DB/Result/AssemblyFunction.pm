package Evolver::DB::Result::AssemblyFunction;

use strict;
use warnings;
use CLASS;

use base 'Evolver::DB::Result';

CLASS->table("assembly_function");

CLASS->add_columns(
  "id",
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
    is_nullable => 0,
    size => undef,
  },
);
CLASS->set_primary_key("id");
CLASS->add_unique_constraint("name_unique", ["name"]);
CLASS->has_many(
  "runs",
  "Evolver::DB::Result::Run",
  { "foreign.assembly_function_id" => "self.id" },
);

1;
