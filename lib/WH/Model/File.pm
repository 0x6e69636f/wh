package WH::Model::File;
use Moose;
use List::MoreUtils qw/firstidx/;
use WH::Model::Message;
# extends 'WH::Model::VersionNode';
with 'Mongoose::Document'; 

has 'file_id' => (is=>'rw',isa=>'Str',required=>0);
has 'name' => (is=>'ro', isa=>'Str', required=>1); 
has 'date' => (is=>'ro', isa=>'Str', required=>1, default=>sub{ time });
has 'owner_id' => (is=>'ro', isa=>'Str', required=>1);
has 'removed' => (is=>'rw', isa=>'Bool', required=>1, default=>0);
has 'permissions' => (is=>'rw', isa=>'HashRef[Int]');
has 'permission_level' => (is=>'rw', isa=>'Int', required=>1, default=>0); 
has 'description' => (is=>'rw', isa=>'Str', required=>0);
has 'keywords' => (is=>'rw', isa=>'Str', required=>0, default=>'');
has 'parent' => (is=>'rw', isa=>'Str');
has 'format' => (is=>'ro', isa=>'Str', required=>0);
has 'content_type' => (is=>'ro', isa=>'Str', required=>0);
has 'size' => (is=>'rw', isa=>'Num', required=>1, default=>0);
has 'dir' => (is=>'ro',isa=>'Bool',required=>1, default=>1);
has 'versions' => (is=>'rw', isa=>'HashRef[Str]', required=>1, default=>sub{ {} });
has 'messages' => (is=>'rw', isa=>'ArrayRef[WH::Model::Message]', required=>1, default=>sub{ [] });

sub get_class {
  my ($self) = @_;
  my $template_name = $self->dir ? 'dir' : 'file';

  my %formats = (
    'jpg' => 'image',
    'png' => 'image',
    'gif' => 'image',
    'bmp' => 'image',
    'wav' => 'sound',
    'mp3' => 'sound',
    'ogg' => 'sound',
    'aiff' => 'sound'
  );

  my $format = lc($self->format);
  my $match = $formats{$format};
  $template_name = $match if defined $match;

  return $template_name;
}

sub get_last_version_key{
  my ($self) = @_;
  my $last;
  warn "Getting last version key";
  for my $k(keys %{$self->versions}){
    $last=$k if $k>$last;
  }
  warn "v = $last";
  return $last;
}

sub get_last_version{ return $_[0]->versions->{$_[0]->get_last_version_key}; }

sub version_exists{ return defined $_[0]->versions->{$_[1]}; }

sub get_version_or_last{
  my ($self, $version) = @_;
  if(defined $version && $self->version_exists($version)){
    warn "getting version $version";
    return $self->versions->{$version};
  }else{
    warn "getting last version";
    return $self->get_last_version;
  }
}

# sub get_version{ return defined $_[0]->versions->{$_[1]} ? $_[0]->versions->{$_[1]}; : $_[0]->get_last_version; }

no Moose;
__PACKAGE__->meta->make_immutable;
1;