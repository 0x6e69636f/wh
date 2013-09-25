package WH::Model::Root;
use Moose;
# extends 'WH::Model::VersionNode'; 
with 'Mongoose::Document';

has 'name'=>(is=>'ro', isa=>'Str', required=>1); 
has 'date'=>(is=>'ro', isa=>'Str', required=>1, default=>sub{ time });
has 'owner'=>(is=>'ro', isa=>'Str', required=>1);
has 'public'=>(is=>'rw', isa=>'Bool', required=>1, default=>1); 
has 'description'=>(is=>'rw', isa=>'Str', required=>0);


no Moose;
__PACKAGE__->meta->make_immutable;
1;