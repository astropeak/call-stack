#!/usr/bin/perl

use Tokener;
use ASTer;
use Aspk::Debug;

my $file = @ARGV[0];
die "Usage: perl main.pl FILE_NAME\n" unless defined $file;

my $tk = Tokener->new($file);
my $aster = ASTer->new($tk);
$aster->build();

# add enter and exit trace
$aster->traverse({postfunc=>
                      sub{
                          my $para = shift;
                          my $data = $para->{data};
                          my $node = $para->{node};
                          if ($data->{type} eq 'subname') {
                              $node->add_child(Aspk::Tree->new({data=>{type=>'other',value=>"\nprint 'Enter ".$data->{value}."'".'."\n";'}}), 1);
                              # $node->add_child(Aspk::Tree->new({data=>{type=>'other',value=>"print 'Exit ".$data->{value}."'".'."\n";'."\n"}}), -1);
                              my @new_children;
                              foreach (@{$node->prop(children)}) {
                                  my $d = $_->prop(data);
                                  if ($d->{type} eq 'literal' && $d->{value} eq 'return') {
                                      push @new_children, Aspk::Tree->new({data=>{type=>'other',value=>"print 'Exit ".$data->{value}."'".'."\n";'."\n"}});
                                  }

                                  push @new_children, $_;
                              }

                              $node->prop(children, \@new_children);
                          }
                  }});


# for debug, display new ast with traces node added
$aster->display();

# write to file
open my $fh, '>', "add_trace_$file" or die "Can't open file";
$aster->traverse({prefunc=>
                      sub{
                          my $para = shift;
                          my $data = $para->{data};
                          print $fh $data->{value};
                  }});
print "Write done\n";


