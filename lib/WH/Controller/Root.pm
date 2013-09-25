package WH::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';
use WH::Model::User; 
use Digest::MD5 qw(md5_hex);
use WH::Model::Response;
use WH::Model::File;
use Mojo::Upload;
use Mojo::Asset::File;
use IO::File;

sub create{
  my ($self) = @_;

  my $name = $self->param('name');
  my $user_id = $self->session('user_id');
  my $public = $self->param('public');
  my $user = WH::Model::User->find_one($user_id);
  my $r = $self->_create($name, $user, $public);
  $self->render(json=>$r->to_hash);
}


sub _create{
  my ($self, $name, $user, $public) = @_;
  my $r = WH::Model::Response->new;
  $public = $public ? 1 : 0;

  if(defined $name && length $name>0 && defined $user){

    my $root = WH::Model::Root->new(
      name=>$name,
      owner=>$user->_id->to_string,
      public=>$public
    );

    my $id = $root->save if defined $root;
    if(defined $id){
      $r->success(1);
      push(@{$user->roots}, $id->to_string);
    }

  }else{
    $r->msg('Name or User undefined');
  }

  return $r;

}

1;