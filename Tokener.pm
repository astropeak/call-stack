package Tokener;
use Aspk::FileCharIterator;
use Aspk::Debug;

sub new {
    my ($class, $file)= @_;
    my $self={};
    bless $self, $class;

    my @a = _token($file);
    # $self->prop(file, $file);
    $self->prop(token, \@a);
    $self->prop(idx, 2);
    return $self;
}

sub get {
    my ($self) = @_;
    my $i = $self->prop(idx);
    $self->prop(idx, $i+1);
    return $self->prop(token)->[$i];
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

sub _token {
    my ($file) =@_;
    my $fciter=Aspk::FileCharIterator->new($file);
    my @token, $current_other, $t;
    while (1) {
        # match a subname
        $t=$fciter->get('sub\s+\w*');
        # dbgm $t;
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>subname, value=>$t};
            next;
        }

        # match a { or }
        $t=$fciter->get('{|}');
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>literal, value=>$t};
            next;
        }

        # all other things
        $t=$fciter->get();
        # $current_other.=$t unless $t=~/\n/;
        # $current_other.=$t;

        last if ($t eq '');
    };

    return @token;
}

1;