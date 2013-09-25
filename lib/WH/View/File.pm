package WH::View::File;
use Mojo::Base 'Mojolicious::Controller';
use WH::Model::User;
use Digest::MD5 qw(md5_hex);
use WH::Model::Response;
use WH::Model::File;
use Mojo::Upload;
use Mojo::Asset::File;
use IO::File;

sub list{
  my ($self) = @_;
  my $user_id = $self->sesssion('user_id');
  
  if(defined $user_id){

  }


}

1;