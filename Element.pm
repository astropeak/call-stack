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

sub D {
    my ($self)=@_;
    print "Element info: type: ".$self->prop(type).", value: ".$self->prop(value).", child count: ".@{$self->prop(children)}."\n";
}

1;