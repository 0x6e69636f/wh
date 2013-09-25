package WH::Model::Response;
use Moose;
extends 'WH::Model::Object';

has 'success'=>(is=>'rw', isa=>'Bool', required=>1, default=>0);
has 'msg'=>(is=>'rw', isa=>'Str', required=>0);
has 'data'=>(is=>'rw', isa=>'HashRef', default=>sub{ {} });

sub to_hash{ $_[0]->attributes_as_hashref; }

no Moose;
1;