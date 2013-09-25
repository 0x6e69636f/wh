package WH::Controller::Message;
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
	my $content = $self->param('content');
	my $user_id = $self->session('user_id');
}

1;