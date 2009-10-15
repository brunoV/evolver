package Evolver::DB::ResultSeq;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("result_seq");
__PACKAGE__->add_columns(
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
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "optimized_seqs",
  "Evolver::DB::OptimizedSeq",
  { "foreign.seq_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-15 17:25:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ugoA82wf06nkj+6eptq1mw


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->add_unique_constraint('seq_unique', [ 'seq' ]);
1;
