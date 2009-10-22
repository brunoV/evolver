package Evolver::DB::Result::ResultSeq;

use strict;
use warnings;
use CLASS;

use base 'Evolver::DB::Result';

CLASS->table("result_seq");
CLASS->add_columns(
  "id",
  {
    data_type => "INTEGER",
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
  "type",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
CLASS->set_primary_key("id");
CLASS->has_many(
  "optimized_seqs",
  "Evolver::DB::Result::OptimizedSeq",
  { "foreign.seq_id" => "self.id" },
);

CLASS->add_unique_constraint('seq_unique', [ 'seq' ]);

1;
