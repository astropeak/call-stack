package ArrayIter;
# use Aspk::Debug;

sub new {
    my ($class, @array)= @_;
    my $self={};
    bless $self, $class;

    $self->prop(array, \@array);
    $self->prop(idx, 0);
    return $self;
}

sub get {
    my ($self) = @_;
    my $i = $self->prop(idx);
    $self->prop(idx, $i+1);
    return $self->prop(array)->[$i];
}

sub back {
    my ($self, $count) = @_;
    $count||=1;
    my $i = $self->prop(idx);
    $i-=$count;
    $i=0 if $i<0;
    $self->prop(idx, $i);
    return $self;
}

# Get or set a property of the object
sub prop {
    my ($self, $name, $value) = @_;
    # print "In prop. name: $name, value: $value\n";
    # dbgm $name $value;

    if (defined($value)) {
        $self->{"_$name"} = $value;
        return $self;
    } else {
        return $self->{"_$name"};
    }
}

1;
