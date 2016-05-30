package ASTerNew1;
# use parent Aspk::Tree;
use Aspk::Debug;
use ArrayIter;
use Element;

use Scalar::Util qw(reftype);
my %PAIR=('('=>')', '{'=>'}');

sub new {
    my ($class, $token_iter)= @_;
    my $self={};
    bless $self, $class;

    $self->prop(token_iter, $token_iter);
    $self->prop(data, Element->new({type=>'ROOT', value=>''}));
    return $self;
}

# Get or set a property of the object
sub prop {
    my ($self, $name, $value) = @_;
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
    my $root = $self->prop(data);

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
            $root->add_child($pair);
        } else {
            $root->add_child(Element->new($token));
        }
    }

    # dbgm $root;
    $self->display();

    # transform subname and pair to sub
    $root->traverse({prefunc=>
                         sub{
                             my $para = shift;
                             my $node = $para->{node};
                             # if ($node->prop(data)->{type} eq 'line-element') {
                             # parse_sub($node);
                             # parse_return_exp($node);
                             # }
                             # parse_line_element_simple($node);
                             parse_line_element_1($node);
                     }});

}

sub parse_line_element_1{
    my ($node) = @_;
    my $iter = ArrayIter->new(@{$node->prop(children)});
    dbgm $iter;
    my @rst = build_ast($iter);
    $node->prop(children, \@rst);
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
    my $node = Element->new({type=>'pair',value=>$left});
    while (1) {
        $token = $token_iter->get();
        die "Error" if $token->{value} eq '';

        if (exists $table->{$token->{value}}) {
            # $token_iter->back();
            my $pair=parse_pair($token_iter, $token->{value});
            $node->add_child($pair);
        } elsif ($token->{value} eq $right) {
            last;
        } else {
            $node->add_child(Element->new($token));
        }
    }
    return $node;
}

sub display {
    my ($self) = @_;
    my $root=$self->prop(data);
    $root->traverse({prefunc=>
                         sub{
                             my $para = shift;
                             my $node = $para->{node};
                             my $depth = $para->{depth};
                             print ' 'x($depth*4).'type: '.$node->prop(type).', '.'value: '.$node->prop(value)."\n";
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



my %SyntaxTable=
    (
     '_k{'=>[{value=>'$1', type=>'$2'},
             {type=>'pair',value=>'{'}],

     '_k({'=>[{value=>'$1'},
              {type=>'pair',value=>'('},
              {type=>'pair',value=>'{'}],

     # 'sub'=>[{syntax=>'_k{', para=>['', 'subname']}],
     'sub'=>[{type=>'subname', value=>'.*'},
             {type=>'pair', value=>'{'}],

     'if'=>[{syntax=>'_k({', para=>'if'},
            {syntax=>'_k({', para=>'elsif', count=>[0]},
            {syntax=>'_k{', para=>['else', 'literal'], count=>[0,1]}],

     'for'=>[{syntax=>'_k({',para=>'for'}],
     'line_element'=>[{value=>'[^;]', count=>[0]},
                      {type=>'literal',value=>';'}]
    );


foreach my $key (keys %SyntaxTable) {
    syntax_convert_data($SyntaxTable{$key});
}

# dbgm \%SyntaxTable;

my @MatchSet=qw(if sub for);
# my @MatchSet=qw(if);
sub build_ast {
    my ($tk_iter)=@_;
    my @rst;
    while ($tk_iter->get()) {
        $tk_iter->back();
        my $t;
        foreach (@MatchSet) {
            if ($t=parse($tk_iter, $_, $SyntaxTable{$_})) {
                # dbgm $_;
                # die "undefined " if not defined $t;
                push @rst, $t;
                last;
            }
        }
        # not matched in syntax table
        # dbgm $t;
        unless (defined $t){
            push @rst, $tk_iter->get();
        }
    }
    # dbgm \@rst;
    return @rst;
}

sub parse {
    my ($tk_iter, $id, $syntax)=@_;
    dbgm  $id, $syntax;
    # my @syntax=@{$SyntaxTable{$id}};
    # print $tk_iter->prop(idx)."\n";
    my $rst = Element->new({type=>$id});
    foreach my $st (@{$syntax}) {
        if (exists $st->{syntax}) {
            # count and para not dealed.
            # dbgm $_->{syntax};
            my $st1 = $SyntaxTable{$st->{syntax}};
            # dbgm $st1;
            $st1 = syntax_apply_para($st1, $st->{para});
            # if ($st->{syntax} eq '_k({') {
            # dbgm $st1;
            # }

            # print "token type: ". $tk_iter->prop(array)->[$tk_iter->prop(idx)]->prop(type) .
            #  ", value: ". $tk_iter->prop(array)->[$tk_iter->prop(idx)]->prop(value) ."\n";

            my $t=parse($tk_iter,$st->{syntax}, $st1);
            if ($t) {
                # dbgm $st->{syntax};
                $rst->add_child($t);
            } else {
                return undef;
            }
        } else {
            my $t=$tk_iter->get();
            return undef unless $t;

            print "st: $st->{type}, $st->{value}\n";
            print "t: ".$t->prop(type).", ".$t->prop(value).", index:".$tk_iter->prop(idx)."\n";

            if ($t->prop(type) =~ /^$st->{type}$/ &&
                $t->prop(value) =~ /^$st->{value}$/) {
                print "AAAA, matched\n";
                $rst->add_child($t);
            } else {
                $tk_iter->back();
                return undef;
            }
        }
    }
    # dbgm $rst;
    return $rst;
}

sub syntax_convert_data {
    my ($syntax) = @_;
    # dbgm $syntax;
    foreach (@{$syntax}) {
        # dbgm $_;
        if ((exists $_->{para} ) && (reftype($_->{para}) ne 'ARRAY'))  {
            $_->{para} = [$_->{para}];
            # dbgm $_->{para};
        }
        if (not exists $_->{type}) {
            $_->{type} = '.*';
        }
        if (not exists $_->{value}) {
            $_->{value} = '.*';
        }
        if (not exists $_->{count}) {
            $_->{count} = [1,1];
        }

        # quoat the special char
        $_->{type} =~ s/\(/\\(/g;
        $_->{type} =~ s/\{/\\{/g;
        $_->{value} =~ s/\(/\\(/g;
        $_->{value} =~ s/\{/\\{/g;
        # dbgm $_;
    }
}

sub syntax_apply_para{
    my ($syntax, $para) = @_;
    if (@{$para} >0) {
        # dbgm $syntax;
        # dbgm $para;
    }
    my @rst;
    foreach my $st (@{$syntax}) {
        my $t;
        # dbgm $st;
        foreach my $key (keys %{$st}) {
            $t->{$key}=$st->{$key};
            $t->{$key}=~s/\$1/$para->[0]/g;
            $t->{$key}=~s/\$2/$para->[1]/g;
        }
        # dbgm $t;
        push @rst, $t;
    }
    # $rst = $syntax;
    return \@rst;
}

1;