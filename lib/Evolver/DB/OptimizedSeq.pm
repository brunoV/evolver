package Evolver::DB::OptimizedSeq;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("optimized_seq");
__PACKAGE__->add_columns(
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
  "type",
  {
    data_type => "varchar",
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
  "seq",
  {
    data_type => "varchar",
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
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("seq_unique", ["seq"]);
__PACKAGE__->belongs_to("run_id", "Evolver::DB::Run", { id => "run_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-12 16:42:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6L/NQa17A0dxfUIHvRqwVA


# You can replace this text with custom content, and it will be preserved on regeneration

1;
