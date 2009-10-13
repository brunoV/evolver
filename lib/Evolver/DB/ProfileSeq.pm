package Evolver::DB::ProfileSeq;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
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
  "Evolver::DB::ProfileSeqRun",
  { "foreign.profile_seq_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-12 22:37:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HaXTyt1YFZiGlTQnb++3Xg

# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->many_to_many('runs', 'profile_seq_runs', 'run_id');

1;
