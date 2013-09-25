package WH::Model::Object;
use Moose;
with 'MooseX::AttributeCloner';

sub to_hash{
	my $self=shift;
	my $h = $self->attributes_as_hashref;
	if(defined $self->_id){
		$h->{id}=$self->_id->to_string;
	}
	return $h;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
