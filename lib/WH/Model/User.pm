package WH::Model::User;
use Moose;
use WH::Controller::Friendship;
with 'Mongoose::Document';
extends 'WH::Model::Object';
  
has 'login'=>(is=>'ro', isa=>'Str', required=>1);
has 'password'=>(is=>'ro', isa=>'Str', required=>1); 
has 'name'=>(is=>'ro', isa=>'Str', required=>1);
# has 'default_root'=>(is=>'rw', isa=>'Str', required=>1, default=>sub{$_[0]->_id->to_string});
# has 'roots'=>(is=>'rw', isa=>'ArrayRef[Str]', required=>1, default=>sub{[]});
has 'admin'=>(is=>'rw', isa=>'Bool', required=>1, default=>0);

has 'friend_requests'=>(is=>'rw', isa=>'ArrayRef', required=>1, default=>sub{[]});
has 'friends'=>(is=>'rw', isa=>'ArrayRef', required=>1, default=>sub{[]});

sub is_friend_with{ return WH::Controller::Friendship->_friendship_check($_[0], $_[1]); }
 
no Moose;
1;