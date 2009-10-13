package Evolver::DB::Fitness;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fitness");
__PACKAGE__->add_columns(
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
    size => 20,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);
__PACKAGE__->has_many(
  "runs",
  "Evolver::DB::Run",
  { "foreign.fitness_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-12 22:37:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8SdJZrSaTgcifcEAkF54kA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
