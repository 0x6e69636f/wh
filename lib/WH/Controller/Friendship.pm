package WH::Controller::Friendship;
use Mojo::Base 'Mojolicious::Controller';
use WH::Model::User; 
use Digest::MD5 qw(md5_hex);
use WH::Model::Response;
use WH::Model::File;
use Mojo::Upload;
use Mojo::Asset::File;
use IO::File;
use List::MoreUtils qw(firstidx);

sub create_request{
  my ($self) = @_;
  my $r = WH::Model::Response->new;
  my $session_user_id = $self->session('user_id');
  my $target_id = $self->param('user_id');

  my $session_user = WH::Model::User->find_one($session_user_id) if defined $session_user_id;
  my $target_user = WH::Model::User->find_one($target_id) if defined $target_id;

  my $err;

  $err = 'User undefined' if !defined $session_user || !defined $target_user;
  $err = 'Request already sent' if !defined $err && firstidx { $_ eq $session_user_id } @{$target_user->{friend_requests}} >= 0;
  $err = 'This User has already sent you a request' if !defined $err && firstidx { $_ eq $target_id } @{$session_user->{friend_requests}} >= 0;
  $err = 'You are already friends' if !defined $err && $self->_friendship_check($session_user, $target_user) != 0;

  if(!defined $err){
  	push(@{$target_user->friend_requests}, $session_user_id);
	$session_user->save;
	$target_user->save;	
  }else{ $r->msg($err); }

  $self->render(json=>$r->to_hash);
}

sub approve{
	my ($self) = @_;
	my $r = WH::Model::Response->new;
  	my $session_user_id = $self->session('user_id');
  	my $target_id = $self->param('user_id');

	my $session_user = WH::Model::User->find_one($session_user_id) if defined $session_user_id;
	my $target_user = WH::Model::User->find_one($target_id) if defined $target_id;

	my $err;
	$err = 'User undefined' if !defined $session_user || !defined $target_user;
	my $req_index = firstidx { $_ eq $target_id } @{$session_user->friend_requests};
	$err = 'No request from this user' if ! defined $err && $req_index <0;
	$err = 'You are already friends' if !defined $err && $self->_friendship_check($session_user, $target_user) != 0;

	if(!defined $err){

		push(@{$target_user->friends}, $session_user_id);
	  	push(@{$session_user->friends}, $target_id);

		splice(@{$session_user->friend_requests}, $req_index, 1);

		$session_user->save;
		$target_user->save;

	}else{ $r->msg($err); }

  	$self->render(json=>$r->to_hash);
}

sub remove{
	my ($self) = @_;
	my $r = WH::Model::Response->new;
  	my $session_user_id = $self->session('user_id');
  	my $target_id = $self->param('user_id');

	my $session_user = WH::Model::User->find_one($session_user_id) if defined $session_user_id;
	my $target_user = WH::Model::User->find_one($target_id) if defined $target_id;

	my $err;
	$err = 'User undefined' if !defined $session_user || !defined $target_user;
	$err = 'You are not friends' if !defined $err && $self->_friendship_check($session_user, $target_user) <= 0;

	if(!defined $err){

		push(@{$target_user->friends}, $session_user_id);
	  	push(@{$session_user->friends}, $target_id);
		my $req_index = firstidx { $_ eq $target_id } @{$session_user->friend_requests};
		splice(@{$session_user->friend_requests}, $req_index, 1);

		$session_user->save;
		$target_user->save;

	}else{ $r->msg($err); }

  	$self->render(json=>$r->to_hash);
}

sub decline{
		my ($self) = @_;
	my $r = WH::Model::Response->new;
  	my $session_user_id = $self->session('user_id');
  	my $target_id = $self->param('user_id');

	my $session_user = WH::Model::User->find_one($session_user_id) if defined $session_user_id;
	my $target_user = WH::Model::User->find_one($target_id) if defined $target_id;

	my $err;
	$err = 'User undefined' if !defined $session_user || !defined $target_user;
	my $req_index = firstidx { $_ eq $target_id } @{$session_user->friend_requests};
	$err = 'No request from this user' if !defined $err && $req_index <0;

	if(!defined $err){
		splice(@{$session_user->friend_requests}, $req_index, 1);
		$session_user->save;
	}else{ $r->msg($err); }

  	$self->render(json=>$r->to_hash);
}

sub _friendship_check{
	my ($self, $trigger_user, $target_user) = @_;
	if(defined $trigger_user && defined $target_user){
		my $t1= firstidx { $_ eq $trigger_user->_id->to_string } @{$target_user->friends} >= 0 ? 1 : 0;
		my $t2= firstidx { $_ eq $target_user->_id->to_string } @{$trigger_user->friends} >= 0 ? 1 : 0;

		if($t1 && !$t2){
			# $size_before_add = scalar @{$trigger_user->friends};
			push(@{$trigger_user->friends}, $target_user->_id->to_string);
			$trigger_user->save;
			# $t2 = scalar @{$trigger_user->friends};
		}

		if(!$t1 && $t2){
			push(@{$target_user->friends}, $trigger_user->_id->to_string);
			$target_user->save;
		}

		return $t1 && $t2 ? 1 : 0;
	}else{
		return -1;
	}
}

1;