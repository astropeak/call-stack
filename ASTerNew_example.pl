use Tokener;
use ASTerNew1;
use Aspk::Debug;

my $tk = Tokener->new('test.pl');
my $aster = ASTerNew1->new($tk);
$aster->build();
# Let print move clear
# $aster->remove_token_iter();
# dbgm $aster;
$aster->display();
my $t = $aster->prop(data);
# dbgm $t;