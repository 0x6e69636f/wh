package WH::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
use WH::Model::User;
use Digest::MD5 qw(md5_hex);
use WH::Model::Response;
use WH::Model::Root;
use WH::Controller::Root;
use List::MoreUtils qw/firstidx/;

my @forbidden_names = qw/friends all/;

sub create{
	my ($self) = @_; 
	
	my $login = $self->param('login');
	my $name = $self->param('name');
	my $pwd1 = $self->param('pwd1');
	my $pwd2 = $self->param('pwd2'); 

	my $r = new WH::Model::Response;
	
	my $err;
	$err = "Login undefined" if!defined $login || length $login==0;
	$err = "Login already used" if $self->_user_exist($login) && !defined $err;
	$err = "Name undefined" if (!defined $name || length $name==0) && !defined $err;
	$err = "Passwords undefined" if (!defined $pwd1 || !defined $pwd2) && !defined $err;
	$err = "Invalid Passwords" if (length $pwd1<4 || $pwd1 ne $pwd2) && !defined $err;
	$err = "This name is forbidden" if (firstidx{$name eq $_}) && !defined $err;

	if(!defined $err){
		my $password = md5_hex($pwd1);
		my $user = new WH::Model::User(login=>$login, password=>$password, name=>$name);
		my $id = $user->save;
		if(defined $id){
			$r->success(1);
			# my $root_creation = WH::Controller::Root->_create($login,$user,0);
			# $r->msg('root creation failed') if !$root_creation->success;
			# $r->data->{root_creation} = $root_creation->success;
		}

	}else{
		$r->msg($err);
	}

	$self->render(json=>$r->to_hash);
}

sub _user_exist{
	my ($self, $login) = @_;
	return defined WH::Model::User->find_one({login=>$login}) ? 1 : 0;
}

sub lang{
	my ($self) = @_;
	my $lang = $self->param('lang');
    $self->session('lang'=>$lang) if defined $lang;
    warn $self->session('lang');
    $self->redirect_to('/');
}

sub set_session_root {   
	my ($self) = @_;
	my $user = WH::Model::User->find_one($self->session('user_id'));
	my $root_id = $self->param('root_id');
	my $r = new WH::Model::Response;

	if(defined $user){
		my $root_index = firstidx {$_ eq $root_id} @{$user->roots};
		if( $root_index >0){
			$self->session($root_id);
			$r->success(1);
		}
	}

	$self->render(json=>$r->to_hash);
}

sub add_root{
	my ($self) = @_; 
	my $session_user_id = $self->session('user_id');
	my $user_id = $self->param('user_id');
	my $root_id = $self->param('root_id');
	
	my $r = new WH::Model::Response;

	my $session_user = WH::Model::User->find_one($session_user_id);
	my $root = WH::Model::Root->find_one($root_id);
	my $user = WH::Model::User->find_one($user_id);

	if(defined $session_user 
		&& defined $root 
		&& $root->owner eq $session_user_id
		&& defined$user ){

		my $root_index = firstidx { $_ eq $root_id } @{$user->roots};
		if($root_index == -1){
			push(@{$user->roots}, $root_id);
			$user->save;
		}

		$r->success(1);

	}else{
		$r->msg('No way ...');		
	}

	$self->render(json=>$r->to_hash);

}

sub set_default_root{
	my ($self) = @_;
	my $root_id = $self->param('root_id');
	my $session_user_id = $self->session('user_id');
	my $user_id = defined $self->param('user_id') ? $self->param('user_id') : $session_user_id;
	my $user = WH::Model::User->find_one($user_id);
	$self->render(json=>$self->_set_default_root($user, $root_id)->to_hash);
}

sub _set_default_root{
	my ($self, $user, $root_id) = @_;
	my $r = new WH::Model::Response;

	my $session_user_id = $self->session('user_id');
	my $session_user = WH::Model::User->find_one($session_user_id) if defined $session_user_id;
	my $root = WH::Model::Root->find_one($root_id);

	my $err;
	$err = "User or Root undefined" if !defined $user || !defined $root_id;
	$err = "No way" if $user->_id->to_string ne $self->session('user_id') || (defined $session_user && !$session_user->admin);

	if(!defined $err){
		$user->default_root($root_id);
		$user->save;
		$r->success(1);
	}else{
		$r->msg($err);
	}

	return $r;
}


 
sub login{
	my ($self) = @_;

	my $user = WH::Model::User->find_one({
		login=>$self->param('login'), 
		password=>md5_hex($self->param('password')) 
	});

	my $r = new WH::Model::Response;
	if(defined $user){
		$self->session('user_id'=>$user->_id->to_string, 'user_name'=>$user->name);
		# my $session_root = defined $user->default_root ? $user->default_root : $user->_id->to_string;
	}else{ $r->msg("Invalid login/password couple"); }

	$self->redirect_to("/");
}

sub logout {
	my $self=shift;
	if ( defined $self->session("user_id") ) {
		$self->session( expires => 1 );
	}
	$self->redirect_to("/");
}

1;