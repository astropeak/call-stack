#!/usr/bin/perl

use Tokener;
use ASTer;
use Aspk::Debug;
use File::Basename;

my $file = @ARGV[0];
die "Usage: perl main.pl FILE_NAME\n" unless defined $file;

my $tk = Tokener->new($file);
my $aster = ASTer->new($tk);
$aster->build();

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
    qq{print "${\header($file, $row)} Enter $subname. Args: " . main::format_arg(\@_)."\n"; };
}

sub exit_trace {
    my $file=shift;
    my $row=shift;
    my $subname=shift;
    my $exp=shift;
    if (defined $exp){
        $exp="\".($exp).\"";
    } else {
        $exp='none';
    }
    qq{print "${\header($file, $row)} Exit $subname. Exit value: $exp\n"; };
}

# add enter and exit trace
$aster->traverse({postfunc=>
                      sub{
                          my $para = shift;
                          my $data = $para->{data};
                          my $node = $para->{node};
                          if ($data->{type} eq 'subname') {
                              $node->add_child(Aspk::Tree->new({data=>{
                                  type=>'other',
                                  value=>enter_trace($file,$data->{row},$data->{value})
                                                                }}), 1);
                              $node->add_child(Aspk::Tree->new({data=>{
                                  type=>'other',
                                  value=>exit_trace($file, $node->prop(children)->[-1]->prop(data)->{row}, $data->{value})
                                                                }}), -1);

                              # add before all return
                              my @new_children;
                              my $i=0;
                              foreach (@{$node->prop(children)}) {
                                  my $d = $_->prop(data);
                                  if ($d->{type} eq 'literal' && $d->{value} eq 'return') {
                                      my $exp_node=$node->prop(children)->[$i+1];
                                      my $exp;
                                      if ($exp_node->prop(data)->{value} ne ';') {
                                          $exp= $exp_node->prop(data)->{value};
                                      }
                                      push @new_children,
                                      Aspk::Tree->new({data=>{
                                          type=>'other',
                                          value=>exit_trace($file, $_->prop(data)->{row}, $data->{value}, $exp)
                                                       }});
                                  }
                                  push @new_children, $_;
                                  ++$i;
                              }
                              $node->prop(children, \@new_children);
                          }
                  }});


# for debug, display new ast with traces node added
$aster->display();

# write to file
open my $fh, '>', "add_trace_".basename($file) or die "Can't open file";
$aster->traverse({prefunc=>
                      sub{
                          my $para = shift;
                          my $data = $para->{data};
                          print $fh $data->{value};
                  }});
print "Write done\n";


