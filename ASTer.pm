package ASTer;
use parent Aspk::Tree;
# use Aspk::Debug;

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

sub build {
    my ($self) = @_;
    my $token_iter = $self->prop(token_iter);
    my $token, $current_root;
    $current_root = $self;
    my $current_left_brace_count = 0;
    while (1) {
        $token = $token_iter->get();
        last unless defined $token;
        # dbgm $token;

        if ($token->{type} eq 'other' ||
            $token->{type} eq 'string' ||
            $token->{type} eq 'regexp' ||
            $token->{type} eq 'comment') {
            $current_root->add_child(Aspk::Tree->new({data=>$token}));
            next;
        }

        if ($token->{type} eq 'subname') {
            my $t = Aspk::Tree->new({data=>$token, parent=>$current_root});
            $current_root->prop(current_left_brace_count, $current_left_brace_count);
            $current_left_brace_count=0;
            $current_root = $t;
            next;
        }

        if ($token->{type} eq 'literal') {
            if ($token->{value} eq '{') {
                $current_left_brace_count++;
                $current_root->add_child(Aspk::Tree->new({data=>$token}));
            } elsif ($token->{value} eq '}') {
                $current_left_brace_count--;
                $current_root->add_child(Aspk::Tree->new({data=>$token}));
                if ($current_left_brace_count == 0) {
                    if (defined $current_root->prop(parent)) {
                        $current_root = $current_root->prop(parent);
                        $current_left_brace_count = $current_root->prop(current_left_brace_count);
                    }
                }
            } elsif ($token->{value} eq 'return') {
                $token_iter->back();
                my $rst=parse_return_exp($token_iter);
                $current_root->add_child($rst);
            }else {
                $current_root->add_child(Aspk::Tree->new({data=>$token}));
            }
            next;
        }
        die "Cant be here";
    }
}

sub parse_return_exp(){
    my $token_iter = shift;
    my $node = Aspk::Tree->new({data=>{type=>'return_exp',value=>''}});
    my $token = $token_iter->get(); #this is literal 'return'
    $node->add_child(Aspk::Tree->new({data=>$token}));
    my $exp=Aspk::Tree->new({data=>{type=>'exp',value=>''}});
    $node->add_child($exp);
    while (1) {
        $token = $token_iter->get();
        if ($token->{value} eq '{') {
            $token_iter->back();
            my $pair=parse_pair($token_iter);
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
    my $node = Aspk::Tree->new({data=>{type=>'pair',value=>''}});
    my $token = $token_iter->get(); #this is literal '{'
    $node->add_child(Aspk::Tree->new({data=>$token}));
    while (1) {
        $token = $token_iter->get();
        if ($token->{value} eq '{') {
            $token_iter->back();
            my $pair=parse_pair($token_iter);
            $node->add_child($pair);
        } elsif ($token->{value} eq '}') {
            $node->add_child(Aspk::Tree->new({data=>$token}));
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

1;