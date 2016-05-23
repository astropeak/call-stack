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

# add enter and exit trace
$aster->traverse({postfunc=>
                      sub{
                          my $para = shift;
                          my $data = $para->{data};
                          my $node = $para->{node};
                          sub header {
                              my ($file, $row) = @_;
                              return "[".basename($file).":$row]";
                          }

                          if ($data->{type} eq 'subname') {
                              $node->add_child(Aspk::Tree->new({data=>{type=>'other',value=>"\nprint '".header($file, $data->{row})." Enter ".$data->{value}."'".'."\n";'}}), 1);
                              $node->add_child(Aspk::Tree->new({data=>{type=>'other',value=>"print '".header($file, $node->prop(children)->[-1]->prop(data)->{row})." Exit ".$data->{value}."'".'."\n";'."\n"}}), -1);

                              # add before all return
                              my @new_children;
                              foreach (@{$node->prop(children)}) {
                                  my $d = $_->prop(data);
                                  if ($d->{type} eq 'literal' && $d->{value} eq 'return') {
                                      push @new_children, Aspk::Tree->new({data=>{type=>'other',value=>"print '".header($file, $_->prop(data)->{row})." Exit ".$data->{value}."'".'."\n";'."\n"}});
                                  }

                                  push @new_children, $_;
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


