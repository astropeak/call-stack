package Element;
use parent Aspk::Tree;
use Aspk::Debug;

sub new {
    my ($class, $spec)= @_;
    my $self;
    $self = $class->SUPER::new($spec);

    $self->prop(type, $spec->{type});
    $self->prop(value, $spec->{value});

    bless $self, $class;
    return $self;
}

1;