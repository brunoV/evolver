package Evolver::DB::ProfileSeqRun;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("profile_seq_run");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "profile_seq_id",
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "profile_seq_id",
  "Evolver::DB::ProfileSeq",
  { id => "profile_seq_id" },
);
__PACKAGE__->belongs_to("run_id", "Evolver::DB::Run", { id => "run_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-12 16:42:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vFLyaNiHJWVMuOEbqeACYg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
