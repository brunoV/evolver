package Evolver::DB;
use base 'DBIx::Class::Schema::Loader';

__PACKAGE__->dump_to_dir('/home/brunov/lib/evolver/lib/');
__PACKAGE__->connection("dbi:SQLite:db");
