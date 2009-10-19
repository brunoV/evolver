package Evolver::DB::Result;
use CLASS;

use base 'DBIx::Class';

CLASS->load_components('Core');
CLASS->table_class('DBIx::Class::ResultSource::View');

CLASS->table('result');
CLASS->result_source_instance->view_definition(
"select r.id, f.name as fitness, r.profile_algorithm, r.inject_consensus, r.mutation, r.crossover, r.strategy, r.parents,
r.selection, r.preserve, r.population_size, r.generation as max_generation, r.history, r.description as run_description, s.seq, o.custom_score,
o.total_score, o.generation, o.name, r.mutation * r.population_size * o.generation as cost from run r inner join fitness f on f.id = r.fitness_id
inner join optimized_seq o on o.run_id = r.id inner join result_seq s on o.seq_id = s.id;"
);
