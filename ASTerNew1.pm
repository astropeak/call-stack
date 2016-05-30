package ASTerNew1;
use parent Aspk::Tree;
# use Aspk::Debug;
use ArrayIter;

my %PAIR=('('=>')', '{'=>'}');

sub new {
    my ($class, $token_iter)= @_;
    my $self;
    $self = $class->SUPER::new();
    # $self->prop(data, {tag=>$spec->{tag},
    # prop=>$spec->{prop}});

    $self->prop(token_iter, $token_iter);
    $self->prop(data, {type=>'ROOT', value=>''});

    bless $self, $class;
    return $self;
}

# Get or set a property of the object
sub prop {
    my ($self, $name, $value) = @_;
    # print "In prop. name: $name, value: $value\n";
    dbgl $name $value;

    if (defined($value)) {
        $self->{"_$name"} = $value;
        return $self;
    } else {
        return $self->{"_$name"};
    }
}


sub build {
    my ($self) = @_;
    my $token_iter = $self->prop(token_iter);
    my $token, $current_root;
    # while (my $le = parse_line_element($token_iter)) {
    # $self->add_child($le);
    # }

    while (1) {
        $token = $token_iter->get();
        last unless defined $token;

        # dbgh %PAIR;
        if (exists $PAIR{$token->{value}}) {
            # print "HERE";
            # $token_iter->back();
            my $pair=parse_pair($token_iter, $token->{value});
            $self->add_child($pair);
        } else {
            $self->add_child(Aspk::Tree->new({data=>$token}));
        }
    }

    # transform subname and pair to sub
    $self->traverse({postfunc=>
                         sub{
                             my $para = shift;
                             my $node = $para->{node};
                             # if ($node->prop(data)->{type} eq 'line-element') {
                             # parse_sub($node);
                             # parse_return_exp($node);
                             # }
                             parse_line_element_simple($node);
                     }});

}

sub parse_return_exp_orig(){
    my $token_iter = shift;
    my $node = Aspk::Tree->new({data=>{type=>'return_exp',value=>''}});
    my $token = $token_iter->get(); #this is literal 'return'
    $node->add_child(Aspk::Tree->new({data=>$token}));
    my $exp=Aspk::Tree->new({data=>{type=>'exp',value=>''}});
    $node->add_child($exp);
    while (1) {
        $token = $token_iter->get();
        die "Error" if $token->{value} eq '';

        if ($token->{value} eq '{') {
            $token_iter->back();
            my $pair=parse_pair($token_iter, '{');
            $exp->add_child($pair);
        } elsif ($token->{value} eq ';') {
            $node->add_child(Aspk::Tree->new({data=>$token}));
            last;
        } else {
            $exp->add_child(Aspk::Tree->new({data=>$token}));
        }
    }
    return $node;
}

sub parse_pair {
    my $token_iter=shift;
    my $left=shift;
    my $table=\%PAIR;
    my $right=$table->{$left};
    my $node = Aspk::Tree->new({data=>{type=>'pair',value=>$left}});
    # my $token = $token_iter->get(); #this is literal '{'
    # $node->add_child(Aspk::Tree->new({data=>$token}));
    while (1) {
        $token = $token_iter->get();
        die "Error" if $token->{value} eq '';

        if (exists $table->{$token->{value}}) {
            # $token_iter->back();
            my $pair=parse_pair($token_iter, $token->{value});
            $node->add_child($pair);
        } elsif ($token->{value} eq $right) {
            # $node->add_child(Aspk::Tree->new({data=>$token}));
            last;
        } else {
            $node->add_child(Aspk::Tree->new({data=>$token}));
        }
    }
    return $node;
}

sub display {
    my ($self) = @_;
    $self->traverse({prefunc=>
                         sub{
                             my $para = shift;
                             my $data = $para->{data};
                             my $depth = $para->{depth};
                             print ' 'x($depth*4).'type: '.$data->{type}.', '.'value: '.$data->{value}."\n";
                     }});
}

sub remove_token_iter {
    my ($self) = @_;
    $self->traverse({prefunc=>
                         sub{
                             my $para = shift;
                             my $node = $para->{node};
                             $node->prop(token_iter, undef);
                             delete $node->{_token_iter};
                     }});
}


sub parse_line_element_simple{
    my $node = shift;
    my @children = @{$node->prop(children)};
    my @dchildren;
    my $nn=Aspk::Tree->new({data=>{type=>'line_element'}});
    my $child_iter = ArrayIter->new(@children);
    my $d;

    while(my $child=$child_iter->get()) {
        $d = $child->prop(data);
        if ($d->{value} eq ';') {
            $nn->add_child($child);
            push @dchildren, $nn;
            $nn=Aspk::Tree->new({data=>{type=>'line_element'}});
        } elsif ($d->{value} eq 'if') {
            # parse if-statement
            if (@{$nn->prop(children)} == 0) {
                $child_iter->back();
                my $ii = parse_if_statement($child_iter);
                $nn->add_child($ii);

                push @dchildren, $nn;
                $nn=Aspk::Tree->new({data=>{type=>'line_element'}});
            } else {
                # this is the post if statemetn
                $nn->add_child($child);
            }
        }
        elsif ($d->{type} eq 'subname') {
            # parse sub
            my $ii=Aspk::Tree->new({data=>{type=>'sub'}, parent=>$nn});
            $ii->add_child($child);

            $child=$child_iter->get();
            $d=$child->prop(data);
            if ($d->{type} eq 'pair' && $d->{value} eq '{') {
                $ii->add_child($child);
            } else {
                die "parse sub, expect pair {";
            }

            push @dchildren, $nn;
            $nn=Aspk::Tree->new({data=>{type=>'line_element'}});
        }
        else {
            $nn->add_child($child);
        }
    }

    if (@{$nn->prop(children)} > 0) {
        push @dchildren, $nn;
    }
    $node->prop(children, \@dchildren);
}

sub parse_if_statement {
    my ($ci) = @_;
    my $n = Aspk::Tree->new({data=>{type=>'if_statement'}});
    my $nn = Aspk::Tree->new({data=>{type=>'if_part'}, parent=>$n});
    my $c= $ci->get(); #literal if
    $nn->add_child($c);

    $c= $ci->get();
    $d=$c->prop(data);
    if (($d->{type} eq 'pair') && ($d->{value} eq '(')) {
        $nn->add_child($c);

        $c= $ci->get();
        $d=$c->prop(data);
        if (($d->{type} eq 'pair') && ($d->{value} eq '{')) {
            $nn->add_child($c);
        } else {
            die "if statement: expect pair {";
        }
    } else {
        die "if statement: expect pair (";
    }

    # parse all elsif part
    my $flag=1;
    while ($flag) {
        $c= $ci->get();
        $d=$c->prop(data);
        if (($d->{type} eq 'literal') && ($d->{value} eq 'elsif')) {
            $nn = Aspk::Tree->new({data=>{type=>'elsif_part'}, parent=>$n});
            $nn->add_child($c);

            $c= $ci->get();
            $d=$c->prop(data);
            if (($d->{type} eq 'pair') && ($d->{value} eq '(')) {
                $nn->add_child($c);

                $c= $ci->get();
                $d=$c->prop(data);
                if (($d->{type} eq 'pair') && ($d->{value} eq '{')) {
                    $nn->add_child($c);
                } else {
                    die "if statement: expect pair {";
                }
            } else {
                die "if statement: expect pair (";
            }
        } else {
            $ci->back();
            $flag=0;
        }
    }

    # parse all else part
    $c= $ci->get();
    $d=$c->prop(data);
    if (($d->{type} eq 'literal') && ($d->{value} eq 'else')) {
        $nn = Aspk::Tree->new({data=>{type=>'else_part'}, parent=>$n});
        $nn->add_child($c);
        $c= $ci->get();
        $d=$c->prop(data);
        if (($d->{type} eq 'pair') && ($d->{value} eq '{')) {
            $nn->add_child($c);
        } else {
            die "if statement: expect pair {";
        }
    } else {
        $ci->back();
    }

    return $n;
}

# sub parse_if_statement{
#     my $node = shift
#         my @children = @{$node->prop(children)};
#     my @dchildren;
#     my $nn=Aspk::Tree->new({data=>{type=>'line_element'}});
#     for (my $i=0;$i<@children;$i++) {
#         $nn->add_child($children[$i]);
#         if ($children[$i]->prop(data)->{value} eq ';') {
#             push @dchildren, $nn;
#             $nn=Aspk::Tree->new({data=>{type=>'line_element'}});
#         }
#     }

#     if (@{$nn->prop(children)} > 0) {
#         push @dchildren, $nn;
#     }
#     $node->prop(children, \@dchildren);
# }

sub parse_line_element{
    my $token_iter = shift;
    my $line_element=Aspk::Tree->new({data=>{type=>'line-element'}});
    while (1) {
        my $t = $token_iter->get();
        last unless defined $t;

        if ($t->{value} eq '}') {
            $token_iter->back();
            if (@{$line_element->prop(children)} == 0) {
                return undef;
            } else {
                return $line_element;
            }
        }
        if ($t->{value} eq ';') {
            Aspk::Tree->new({data=>$t,parent=>$line_element});
            return $line_element;
        } elsif ($t->{value} eq '{') {
            my $pair=Aspk::Tree->new({data=>{type=>'pair'}, parent=>$line_element});
            Aspk::Tree->new({data=>$t,parent=>$pair});
            while (my $le=parse_line_element($token_iter)) {
                $pair->add_child($le);
            }
            $t=$token_iter->get();
            Aspk::Tree->new({data=>$t,parent=>$pair});
            # die "token should be }" if $t->{value} ne '}';
            if ($t->{value} ne '}') {
                display($line_element);
                die "token should be }";
            }
            return $line_element;
        } else {
            Aspk::Tree->new({data=>$t,parent=>$line_element});
        }
    }
}

sub parse_return_exp(){
    my $le = shift;
    my @children = @{$le->prop(children)};
    my @dchildren;
    my $ssub;
    my $i;
    for ($i=0;$i<@children;$i++) {
        if ($children[$i]->prop(data)->{value} eq 'return') {
            $ssub=Aspk::Tree->new({data=>{type=>'return_exp'}});
            $ssub->add_child($children[$i]);
            push @dchildren, $ssub;
            $ssub=Aspk::Tree->new({data=>{type=>'exp'}, parent=>$ssub});
            ++$i;
            last;
        } else {
            push @dchildren, $children[$i];
        }
    }

    if ($ssub) {
        for (;$i<@children;$i++) {
            $ssub->add_child($children[$i]);
        }
    }
    $le->prop(children, \@dchildren);
}

sub parse_sub {
    my $sle = shift;
    my @children = @{$sle->prop(children)};
    my @dchildren;
    for (my $i=0;$i<@children;$i++) {
        if ($children[$i]->prop(data)->{type} eq 'subname') {
            my $ssub=Aspk::Tree->new({data=>{type=>'sub'}});
            $ssub->add_child($children[$i]);
            ++$i;
            die "should be pair" if $children[$i]->prop(data)->{type} ne 'pair';
            $ssub->add_child($children[$i]);
            push @dchildren, $ssub;
        } else {
            push @dchildren, $children[$i];
        }
    }
    $sle->prop(children, \@dchildren);
}

1;