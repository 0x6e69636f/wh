package WH;
use Mojo::Base 'Mojolicious';
use Mongoose;
use WH::Controller::File;

# This method will run once at server start
sub startup {
  my $self = shift;

  print "\n";
  print "HELLO ! THIS IS WH \n";
  print "\n";


  Mongoose->db('wh');  

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin('RenderFile');

  # Router
  my $r = $self->routes; 

  # Normal route to controller
  $r->get('/')->to(cb=>sub{
    my $c = shift;
      if(defined $c->session('user_id')){
        $c->render('index'); 
      }else{
         $c->render('page/login'); 
      }
    });

  $r->get('/do/:controller/:action')->via('GET','POST')->to(
		namespace=>'WH::Controller',
  		controller=>$self->stash('controller'),
  		action=>$self->stash('action') 
	);

    $r->get('/show/:controller/:action')->via('GET','POST')->to(
    	controller=>$self->stash('controller'),
    	action=>$self->stash('action') 
  );

  # Normal route to controller
  $r->get('/')->to('example#welcome');
}

1;
