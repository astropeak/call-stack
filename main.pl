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
    my $str=shift;
    qq{print "${\header($file, $row)} Exit $subname. Exit value:".( $str};
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
                                  value=>exit_trace($file, $node->prop(children)->[-1]->prop(data)->{row}, $data->{value}, ')."\n";'."\n")
                                                                }}), -1);

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
                                          value=>exit_trace($file, $_->prop(data)->{row}, $data->{value})
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


