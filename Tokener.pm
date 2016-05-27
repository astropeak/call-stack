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
    $self->prop(idx, 0);
    return $self;
}

sub get {
    my ($self) = @_;
    my $i = $self->prop(idx);
    $self->prop(idx, $i+1);
    return $self->prop(token)->[$i];
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

sub _token {
    my ($file) =@_;
    my $fciter=Aspk::FileCharIterator->new($file);
    my @token, $current_other, $t;
    while (1) {
        # match a subname
        $t=$fciter->get('sub\s+\w*\s*(\(.*\))?\s*');
        # dbgm $t;
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>subname, value=>$t};
            next;
        }

        # match a POD
        $t=$fciter->get('\n=[\d\D]*\n=cut.*');
        # dbgm $t;
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>POD, value=>$t};
            next;
        }

        # match a { or }
        $t=$fciter->get('{|}|return|;');
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>literal, value=>$t};
            next;
        }

        # match a string
        $t=get_string($fciter);
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>'string', value=>$t};
            next;
        }

        # match a comment
        $t=get_comment($fciter);
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>'comment', value=>$t};
            next;
        }

        # match a regexp
        $t=get_regexp($fciter);
        if ($t ne '') {
            if ($current_other ne '') {
                push @token, {type=>other, value=>$current_other};
                $current_other='';
            }
            push @token, {type=>'regexp', value=>$t};
            next;
        }

        # all other things
        $t=$fciter->get();
        # $current_other.=$t unless $t=~/\n/;
        $current_other.=$t;

        last if ($t eq '');
    };

    return @token;
}


sub get_string {
    my $fciter=shift;
    my $starter=$fciter->get('\'|"');
    if ($starter eq '') {
        return '';
    }

    my $result = $starter;
    while (1){
        my $c=$fciter->get();
        die "String can't be matched" if $c eq '';

        if ($c eq $starter) {
            return $result.$c;
        } elsif ($c eq "\\") {
            $result.=$c.$fciter->get();
        } else {
            $result.=$c;
        }
    }
    return $result;
}

sub get_comment {
    my $fciter=shift;
    my $result=$fciter->get('#');
    if ($result eq '') {
        return '';
    }

    while (1){
        my $c=$fciter->get();
        last if $c eq '';
        $result.=$c;
        last if $c eq "\n";
    }
    return $result;
}

sub get_regexp {
    my $fciter=shift;
    my $result=$fciter->get('m/|s/|qr/');
    if ($result eq '') {
        return '';
    }

    my $wanted_end = 1;
    $wanted_end = 2 if $result eq 's/';

    my $matched_end=0;
    while (1){
        my $c=$fciter->get();
        die "Regexp can't be matched" if $c eq '';

        $result.=$c;
        if ($c eq '/') {
            ++$matched_end;
            if ($wanted_end == $matched_end) {
                $result.=$fciter->get('\w*');
                return $result;
            }
        } elsif ($c eq "\\") {
            $result.=$fciter->get();
        }
    }
    return $result;
}

1;