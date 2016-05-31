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
    # $self->display();

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

    # transform post if
    # dbgm "BBBBBB";
    $root->traverse({prefunc=>
                         sub{
                             my $para = shift;
                             my $node = $para->{node};
                             if ($node->prop(type) eq 'line_element') {
                                 my @cc = transform_post_if(@{$node->prop(children)});
                                 # dbgh \@cc;
                                 # $node->prop(children, \@cc);

                                 $node->prop(children, []);
                                 foreach (@cc) {
                                     $node->add_child($_);
                                 }

                             }
                             # $node->prop(children, \@cc);
                     }});




}

sub parse_line_element_1{
    my ($node) = @_;
    my $iter = ArrayIter->new(@{$node->prop(children)});
    # dbgm $iter;
    my @rst = build_ast($iter);
    $node->prop(children, \@rst);
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
     'line_element'=>[{value=>'[^;]+', count=>[0]},
                      {type=>'literal',value=>';'}]
    );


foreach my $key (keys %SyntaxTable) {
    syntax_convert_data($SyntaxTable{$key});
}

# dbgm \%SyntaxTable;

my @MatchSet=qw(if sub for line_element);
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
    my $ti_status = $tk_iter->dump();

    dbgm  $id, $syntax;

    # my $ttttt = $tk_iter->get();
    # return undef if not defined $ttttt;
    # dbgm $ttttt;
    # $tk_iter->back();

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
            # ", value: ". $tk_iter->prop(array)->[$tk_iter->prop(idx)]->prop(value) ."\n";

            my $count=$st->{count};
            dbgm $count;
            my $ii=0;
            my $t;
            do {
                $t=parse($tk_iter,$st->{syntax}, $st1);
                if ($t) {
                    # dbgm $st->{syntax};
                    $rst->add_child($t);
                    ++$ii;
                }
                dbgm "BBBB";
                dbgm $ii;
            } while ($t && $ii<$count->[1]);

            unless ($ii <= $count->[1] && $ii>= $count->[0]) {
                $tk_iter->load($ti_status);
                dbgm "return";
                return undef;
            }
        } else {
            my $count=$st->{count};
            dbgm $count;
            my $ii=0;
            my $flag=0;
            do {
                my $t=$tk_iter->get();
                # unless ($t) {
                #     # $tk_iter->load($ti_status);
                #     # return undef;
                #     last;
                # } 

                if (defined $t) {
                    # print "st: $st->{type}, $st->{value}\n";
                    # print "t: ".$t->prop(type).", ".$t->prop(value).", index:".$tk_iter->prop(idx)."\n";

                    if ($t->prop(type) =~ /^$st->{type}$/ &&
                        $t->prop(value) =~ /^$st->{value}$/) {
                        # print "AAAA, matched\n";
                        $rst->add_child($t);
                        ++$ii;
                        $flag=1;
                    } else {
                        $flag=0;
                        $tk_iter->back();
                    }
                } else {
                    $flag=0;
                }

                dbgm "AAAA";
                dbgm $ii;
            } while ($flag == 1 && $ii<$count->[1]);

            unless ($ii <= $count->[1] && $ii>= $count->[0]) {
                $tk_iter->load($ti_status);

                dbgm "return2";
                return undef;
            }
        }
    }
    # dbgm $rst;
    dbgm "return3";
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
        if (not defined $_->{count}->[1]) {
            $_->{count}->[1]=999999999;
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

sub transform_post_if {
    # my ($iter) = @_;
    my $iter = ArrayIter->new(@_);
    # if (@_[2].prop(value) eq 'if') {
    # dbgm \@_;
    # }
    my @a;
    my $b;
    my @c;
    # dbgh $b;
    while (my $t=$iter->get()){
        # dbgm $t;
        # $t->D();
        if ($t->prop(type) eq 'literal' &&
            $t->prop(value) eq 'if') {
            $b = $t;
            if (@a == 0) {
                return @_;
            }
        } else {
            if ($b) {
                push @c, $t;
            } else {
                push @a, $t;
            }
        }
    }
    # dbgh $b;
    if ($b) {
        # 2.
        my $t=pop @c;
        # dbgm $t;
        unless ($t->prop(type) eq 'literal' &&
                $t->prop(value) eq ';') {
            push @c, $t;
        }

        my $p1 = Element->new({type=>'pair',value=>'('});
        foreach (@c) {
            $p1->add_child($_);
        }
        my $p2 = Element->new({type=>'pair',value=>'{'});
        foreach (@a) {
            $p2->add_child($_);
        }
        my $parent= $b->prop(parent);
        $b->prop(parent, '');
        my @rst=($b, $p1, $p2);

        # dbgm \@rst;

        # 3.
        # my $r = parse(ArrayIter->new(@rst), 'if', $SyntaxTable{'if'});
        my @r = build_ast(ArrayIter->new(@rst));
        # print "EEEEEEEEE";
        # dbgm $r;
        # die "Should not be undef" unless $r;
        return @r;
        # return @rst;
    } else {
        return @_;
    }

}

1;