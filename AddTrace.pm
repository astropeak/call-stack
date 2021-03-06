package AddTrace;
use Tokener;
use ASTer;
use Aspk::Debug;
use File::Basename;
use Aspk::Tree;

sub new {
    my ($class, $src, $dest)= @_;
    my $self={};
    bless $self, $class;

    $self->prop(src, $src);
    $self->prop(dest, $dest);
    dbgm $self;
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


sub build{
    my $self=shift;
    dbgm $self;
    my $src = $self->prop('src');
    die "src is undefined" unless defined $src;

    my $tk = Tokener->new($src);
    my $aster = ASTer->new($tk);
    $aster->build();

    $self->prop(tokener, $tk);
    $self->prop(aster, $aster);

    # calculate row number
    my $total_row=1;
    $aster->traverse({prefunc=>
                          sub{
                              my $para = shift;
                              my $data = $para->{data};
                              my $cnt = @{[$data->{value} =~ /\n/g]};
                              $data->{row}=$total_row;
                              $total_row+=$cnt;
                      }
                     });

    $aster->traverse({postfunc=>
                          sub{
                              my $para = shift;
                              my $node = $para->{node};
                              my @children=@{$node->prop(children)};
                              for (my $i=0;$i<@children;++$i){
                                  if ($children[$i]->prop(data)->{type} eq 'return_exp') {
                                      # $children[$i] = transfrom_return_exp($children[$i]);
                                      $node->prop(children)->[$i] = transfrom_return_exp($children[$i]);
                                  }
                              }
                      }});


    # add enter and exit trace at begin sub and end sub
    $aster->traverse({postfunc=>
                          sub{
                              my $para = shift;
                              my $data = $para->{data};
                              my $node = $para->{node};
                              if ($data->{type} eq 'subname') {
                                  $node->add_child(Aspk::Tree->new({data=>{
                                      type=>'other',
                                      value=>enter_trace($src,$data->{row},$data->{value})
                                                                    }}), 1);
                                  $node->add_child(Aspk::Tree->new({data=>{
                                      type=>'other',
                                      value=>exit_trace($src, $node->prop(children)->[-1]->prop(data)->{row}, $data->{value}, ')."\n";'."\n")
                                                                    }}), -1);
                              }
                      }});


    # add enter and exit trace before every return
    $aster->traverse({postfunc=>
                          sub{
                              my $para = shift;
                              my $data = $para->{data};
                              my $node = $para->{node};
                              if ($data->{type} eq 'return_exp_transformed') {
                                  # add before all return
                                  my @new_children;
                                  my $i=0;
                                  foreach (@{$node->prop(children)}) {
                                      my $d = $_->prop(data);
                                      if ($d->{type} eq 'return_exp') {
                                          my $exp_node=$_->prop(children)->[1];
                                          push @new_children,
                                          Aspk::Tree->new({data=>{
                                              type=>'other',
                                              value=>exit_trace($src, $_->prop(data)->{row}, $data->{value})
                                                           }});
                                          push @new_children, $exp_node;
                                          push @new_children,
                                          Aspk::Tree->new({data=>{
                                              type=>'other',
                                              value=>')."\n";'."\n"}});
                                      }
                                      push @new_children, $_;
                                      ++$i;
                                  }
                                  $node->prop(children, \@new_children);
                              }
                      }});


    # write to file
    # open my $fh, '>', "add_trace_".basename($src) or die "Can't open file";
    open my $fh, '>', $self->prop(dest) or die "Can't open file";
    $aster->traverse({prefunc=>
                          sub{
                              my $para = shift;
                              my $data = $para->{data};
                              print $fh $data->{value};
                      }});
}

sub display {
    my $self=shift;
    $self->prop(aster)->display();
}


sub header {
    my ($file, $row) = @_;
    return "[".basename($file).":$row]";
}

sub format_arg {
    my $____idx____=0;
    join ", ", map {\$____idx____++;
                    my $a = "[$____idx____] $_";
                    if (length($a)>18) {
                        substr($a, 18, 999999,"...");
                    };
                    $a;} @_;
}

sub enter_trace {
    my $file=shift;
    my $row=shift;
    my $subname=shift;
    qq{print "${\header($file, $row)} Enter $subname. Args: " . AddTrace::format_arg(\@_)."\n"; };
}

sub exit_trace {
    my $file=shift;
    my $row=shift;
    my $subname=shift;
    my $str=shift;
    qq{print "${\header($file, $row)} Exit $subname. Exit value:".( $str};
}

# transform return statement
sub transfrom_return_exp {
    my $return_exp=shift;
    my $row=$return_exp->prop(data)->{row};
    my @children=@{$return_exp->prop(children)};
    # my $exp=$children[1];
    my $node=Aspk::Tree->new({data=>{type=>'return_exp_transformed'}});
    Aspk::Tree->new({data=>{type=>'other', value=>'if (wantarray()){
 my @___a___=('},
                     parent=>$node});
    $node->add_child($children[1]);
    Aspk::Tree->new({data=>{type=>'other', value=>');
'}, parent=>$node});
    my $node_1 = Aspk::Tree->new({data=>{type=>'return_exp', value=>'', row=>$row}, parent=>$node});
    $node_1->add_child($children[0]);
    my $exp=Aspk::Tree->new({data=>{type=>'exp'}, parent=>$node_1});
    Aspk::Tree->new({data=>{type=>'other', value=>' @___a___'}, parent=>$exp});
    Aspk::Tree->new({data=>{type=>'literal', value=>';'}, parent=>$node_1});

    # else part
    Aspk::Tree->new({data=>{type=>'other', value=>'
 } else {
 my $___a___=('},
                     parent=>$node});
    $node->add_child($children[1]);
    Aspk::Tree->new({data=>{type=>'other', value=>');
'}, parent=>$node});
    $node_1 = Aspk::Tree->new({data=>{type=>'return_exp', value=>'', row=>$row}, parent=>$node});
    $node_1->add_child($children[0]);
    my $exp=Aspk::Tree->new({data=>{type=>'exp'}, parent=>$node_1});
    Aspk::Tree->new({data=>{type=>'other', value=>' $___a___'}, parent=>$exp});
    Aspk::Tree->new({data=>{type=>'literal', value=>';'}, parent=>$node_1});

    Aspk::Tree->new({data=>{type=>'other', value=>'
}'}, parent=>$node});

    return $node;
}

1;