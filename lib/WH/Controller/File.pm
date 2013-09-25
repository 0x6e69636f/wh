package WH::Controller::File;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use WH::Model::User; 
use WH::Model::Message;
use Digest::MD5 qw(md5_hex);
use WH::Model::Response; 
use WH::Model::File;
use Mojo::Upload;
use Mojo::Asset::File;
use IO::File;
use File::Temp;

my $root = 'D:/wh_files';

my %permissions_levels = (
  0 => 'none',
  1 => 'read',
  2 => 'edit',
  3 => 'full'
);

my %default_permissions = (
  'all' => 0,
  'friends' => 1
);

sub _create_file{
  my ($self, $name, $parent, $user_id, $is_dir, $format, $content_type) = @_;

  my $user = WH::Model::User->find_one($user_id) if defined $user_id;
  my $file = undef;

  if( defined $parent && length $parent>0 ){
    return undef if !defined WH::Model::File->find_one($parent);
  }

  my $err;
  $err = 'forbidden' if !$self->_user_can_write_in_dir($user,$parent);
  $err = 'name undefined' if !defined $err && (!defined $name || length $name==0);
  $err = 'user not found' if !defined $err && !defined $user;

  if(!defined $err){
    $file = WH::Model::File->new(
      name=>$name,
      owner_id=>$user_id,
      parent=>$parent,
      dir=>$is_dir == 1 ? 1 : 0,
      permissions=>\%default_permissions,
      format=>defined $format ? $format : '',
      content_type=>defined $content_type ? $content_type : ''
    );

    my $id = $file->save;
    return undef if !defined $id;
    my $file_id = $self->_generate_file_id($id->to_string);
    $file->file_id($file_id);
    $file->save;
  }else{ warn $err; return undef; }

  return $file;
}
 
sub _generate_file_id {
  my ($self, $id, $i) = @_;

  my $test = WH::Model::File->find_one({file_id=>$id});
  if(defined $test){
    return $self->_generate_file_id($id,$i++);
  }else{
    $i = '' if !defined $i;
    return $id.$i;
  }
}

sub _user_can_write_in_dir{
  my ($self, $user, $dir_id) = @_;

  return 1;
}

sub create_dir{ 
  my ($self) = @_;
  my $name = $self->param('name');
  my $parent = $self->param('parent');
  my $user_id = $self->session('user_id'); 
  my $r = WH::Model::Response->new; 

  if(defined $user_id){  

    my $dir = $self->_create_file($name, $parent, $user_id, 1);

    if(defined $dir){
      $r->success(1);
      $r->data->{dir} = $dir->file_id;
    }
  }

  $self->render(json=>$r->to_hash);
}

sub upload{ 
  my ($self) = @_;

  my $r = WH::Model::Response->new; 
  
  my $user_id = $self->session('user_id'); 
  
  my $parent = $self->param('parent') || '';
  my $public = $self->param('public');
  my @files = $self->param('files');

  my $total = scalar @files;
  my $done = 0;

  for my $fu (@files){ 
    my $upload = Mojo::Upload->new($fu);

    my $err;
    $err = "Upload Failed" if(!defined $upload || !defined $upload->filename);
    $err = "User not connected" if(!defined $user_id);  

    if(!defined $err){

      my $file_name = $upload->filename; 
      my $content_type = $upload->headers->content_type;

      my ($ext) = $file_name =~ /([^.]+)$/;
      $file_name =~ /$([^.]+)/;
      my $dir_path = "$root/$parent/";
      
      # unless(-d $dir_path){
      #     mkdir $dir_path or die;
      # }

      my $file = WH::Model::File->find_one({parent=>$parent, name=>$file_name});

      if(!defined $file){
        $file = $self->_create_file($file_name, $parent, $user_id, 0, $ext, $content_type);
      }

      if(defined $file){

        my $f_name = $file->file_id.scalar(keys %{$file->versions});
        my $file_path = join('/',$root,$parent,$f_name);

        my $t = time;
        if(defined $f_name){
          my $client = MongoDB::MongoClient->new;
          my $db = $client->get_database( 'wh' );
          my $grid = $db->get_gridfs;
          my $asset = $upload->asset;

          open my $fh, '<', \do { my $x = $asset->slurp };
          my $id = $grid->insert($fh, {"filename"=>$f_name});

          if(defined $id && length $id>0 && $grid->find_one({filename=>$f_name})){ 
            $file->versions->{$t} = $f_name;
            $file->removed(0);
            $file->save;
          }

          $done++;
        }
      }else{ $r->msg('error during file creation'); }
    }
  } 

  $r->success(1) if $done == $total;
  $r->msg("$done of $total files uploaded");

  $self->render(json=>$r->to_hash);
}


sub _file_exists{ 
  my ($self, $dir, $file_name) = @_;
  return defined WH::Model::File->find_one({parent=>$dir, name=>$file_name});
}

sub get{
  my ($self) = @_;
  my $user_id = $self->session('user_id');
  my $file_id = $self->param('id');

  my $user = WH::Model::User->find_one($user_id) if defined $user_id;
  my $file = $self->_get_file($file_id);
  my $err;
  $err = 'user not found' if !defined $user;
  $err = 'forbidden' if !defined $err && !$self->_user_can_read_file($user, $file);

  if(!defined $err){  
    my $version = $self->param('v');

    my $f_name = $file->get_version_or_last($version);

    my $client = MongoDB::MongoClient->new;
    my $db = $client->get_database( 'wh' );
    my $grid = $db->get_gridfs;

    if(defined $f_name){
      warn "rendering $f_name";
      my $g_file = $grid->find_one({filename=>$f_name});
      $self->render_file(data=>$g_file->slurp, format=>$file->content_type, filename=>$file->name) if defined $file;  
    }else{
      warn "rendering undef";
      $self->render(json=>{});
    }
  }else{
    $self->render(json=>{msg=>$err});
  }
}

sub change_permissions{
  my ($self) = @_;
  my $file = $self->_get_file($self->param('file'));
  my $perm_level = int($self->param('perm_level'));
  my $user = $self->param('user');
  my $owner_id = $self->session('user_id');
  my $r = WH::Model::Response->new;

  my $owner = WH::Model::User->find_one($owner_id) if defined $owner_id;

  my $err;
  $err = 'User not found' if !defined $user;
  $err = 'File not found' if !defined $err && !defined $file;
  $err = 'permission level undefined' if !defined $err && !defined $perm_level;
  $err = 'invalid permission level' if !defined $err && (!defined $permissions_levels{$perm_level} );
  $err = 'Forbidden' if !defined $err && ($file->owner_id ne $owner_id);

  if(!defined $err){
    $file->permissions->{$user} = $perm_level;
    $file->save;
    $r->msg('done');
    $r->success(1);
  }else{
    $r->msg($err);
  }

  $self->render(json=>$r->to_hash);
}




sub _get_file{
  my ($self, $file_id) = @_;
  my $file = WH::Model::File->find_one($file_id) if defined $file_id;
  return defined $file ? $file : undef;
}

sub _user_can_read_file {
  my ($self, $user, $file) = @_;
  return if !defined $user || !defined $file;
  return 1 if $user->_id->to_string eq $file->owner_id;
  return $self->_get_user_permissions_on_file($user, $file);
}

sub _get_user_permissions_on_file{
  my ($self, $user, $file) = @_;

  return -1 if !defined $user || !defined $file;

  my $user_id = $user->_id->to_string;

  return 3 if $file->owner_id eq $user_id;
  return $file->permissions->{$user_id} if defined $file->permissions->{$user_id};

  my $owner = WH::Model::User->find_one($file->owner_id);
  return $file->permissions->{friends} if $owner->is_friend_with($user);
  return $file->all;
}


sub message {
  my ($self) = @_;
  my $file_id = $self->param('file_id');
  my $content = $self->param('content');
  my $user_id = $self->session('user_id');
  my $r = WH::Model::Response->new; 
  my $user = WH::Model::User->find_one($user_id) if defined $user_id;
  my $file = $self->_get_file($file_id);

  my $err;
  $err = 'File not found' if !defined $file;
  $err = 'User not found' if !defined $err && !defined $user;
  $err = 'Content Undefined' if !defined $err && (!defined $content || length $content==0 && !defined $user_id);
  $err = 'Forbidden' if !defined $err && !$self->_user_can_read_file($user, $file);

  if(!defined $err){
    my $msg = WH::Model::Message->new(content=>$content, author=>$user_id);
    if(defined $msg){
      push(@{$file->messages}, $msg);
      $file->save;
      $r->success(1);
    }else{ $r->msg('Error during message creation'); }
  }else{ $r->msg($err); }

  $self->render(json=>$r->to_hash);
}

sub remove {
  my ($self) = @_;
  my $file_id = $self->param('file_id');
  my $user_id = $self->session('user_id');
  my $removed = int($self->param('removed')) > 0 ? 1 : 0;

  my $user = WH::Model::User->find_one($user_id);
  my $file = WH::Model::File->find_one($file_id);

  my $r = WH::Model::Response->new;
  if($self->_get_user_permissions_on_file($user, $file) == 3){
    $file->removed($removed);
    $file->save;
    $r->success(1);
    $r->msg('Successfully Removed');
  }else{ $r->msg('Forbidden'); }

  $self->render(json=>$r->to_hash);
} 


1;



# sub get{
#   my ($self) = @_;
#   my $user_id = $self->session('user_id');
#   my $file_id = $self->param('id');
#   my $file = WH::Model::File->find_one($file_id);
#   my $version = $self->param('v');
#   warn "Version = $version";
#   my $path = join('/',$root, $file->parent, $file->get_version_or_last($version));
#   if(defined $path){
#     warn "getting ".$file->name." at $path";
#     $self->render_file(filepath=>$path, format=>$file->format, filename=>$file->name) if defined $file;  
#   }else{
#     $self->render_file(undef);
#   }
# }

# sub upload{ 
#   my ($self) = @_;

#   my $r = WH::Model::Response->new; 
  
#   my $user_id = $self->session('user_id'); 
  
#   my $parent = $self->param('parent') || '';
#   my $public = $self->param('public');
#   my @files = $self->param('files');

#   my $total = scalar @files;
#   my $done = 0;

#   for my $fu (@files){ 
#     my $upload = Mojo::Upload->new($fu);

#     my $err;
#     $err = "Upload Failed" if(!defined $upload || !defined $upload->filename);
#     $err = "User not connected" if(!defined $user_id);  

#     if(!defined $err){

#       my $file_name = $upload->filename; 
#       my ($ext) = $file_name =~ /([^.]+)$/;
#       $file_name =~ /$([^.]+)/;
#       my $dir_path = "$root/$parent/";
      
#       unless(-d $dir_path){
#           mkdir $dir_path or die;
#       }



#       my $file = WH::Model::File->find_one({parent=>$parent, name=>$file_name});

#       if(!defined $file){

#         $file = WH::Model::File->new(
#           name=>$file_name, 
#           format=>$ext,
#           size=>$upload->size,
#           owner=>$user_id,
#           parent=>$parent,
#           dir=>0
#         );
#         $file->save;
#       }

#       my $f_name = $file->_id->to_string.scalar(keys %{$file->versions});
#       my $file_path = join('/',$root,$parent,$f_name);

#       my $t = time;
#       if(defined $file_path){
#         $upload->move_to($file_path);
#         $file->versions->{$t} = $f_name;
#         $file->save;
#         $done++;
#       }
#     }
#   } 

#   $r->success(1) if $done == $total;
#   $r->msg("$done of $total files uploaded");

#   $self->render(json=>$r->to_hash);
# }