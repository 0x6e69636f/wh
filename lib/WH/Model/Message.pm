package WH::Model::Message;
use Moose;
use List::MoreUtils qw/firstidx/;
# extends 'WH::Model::VersionNode';
with 'Mongoose::Document'; 

has 'author'=>(is=>'ro', isa=>'Str', required=>1); 
has 'date'=>(is=>'ro', isa=>'Str', required=>1, default=>sub{ time });
has 'content'=>(is=>'ro', isa=>'Str', required=>0);
has 'data'=>(is=>'rw', isa=>'HashRef', required=>0, default=>sub{{}});

no Moose;
1;