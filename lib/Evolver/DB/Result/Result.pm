package Evolver::DB::Result::Result;
use strict;
use warnings;

use CLASS;

use base 'Evolver::DB::Result';

CLASS->table_class('DBIx::Class::ResultSource::View');

CLASS->table('result');
CLASS->result_source_instance->view_definition(
"select r.id, f.name as fitness, r.profile_algorithm, r.inject_consensus, r.mutation, r.crossover, r.strategy, r.parents,
r.selection, r.preserve, r.population_size, r.generation as max_generation, r.history, r.description as run_description, s.seq, o.custom_score,
o.total_score, o.generation, o.name, r.mutation * r.population_size * o.generation as cost from run r inner join fitness f on f.id = r.fitness_id
inner join optimized_seq o on o.run_id = r.id inner join result_seq s on o.seq_id = s.id;"
);

CLASS->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "fitness",
  {
    data_type => "varchar",
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
  "max_generation",
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
  "run_description",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
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
  "seq",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "cost",
  {
    data_type => "float",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);

1;
