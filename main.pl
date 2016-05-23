use Tokener;
use ASTer;
use Aspk::Debug;

my $file = 'test.pl';
my $tk = Tokener->new($file);
my $aster = ASTer->new($tk);
$aster->build();


$aster->traverse({postfunc=>
                      sub{
                          my $para = shift;
                          my $data = $para->{data};
                          my $node = $para->{node};
                          if ($data->{type} eq 'subname') {
                              $node->add_child(Aspk::Tree->new({data=>{type=>'other',value=>'print "Enter '.$data->{value}.'";'}}), 1);
                              $node->add_child(Aspk::Tree->new({data=>{type=>'other',value=>'print "Exit '.$data->{value}.'";'}}), -1);
                          }
                  }});

# $aster->display();
open my $fh, '>', "add_trace_$file" or die "Can't open file";

$aster->traverse({prefunc=>
                      sub{
                          my $para = shift;
                          my $data = $para->{data};
                          print $fh $data->{value};
                  }});

print "Write done\n";


