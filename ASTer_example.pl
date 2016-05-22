use Tokener;
use ASTer;
use Aspk::Debug;

my $tk = Tokener->new('test.pl');
my $aster = ASTer->new($tk);
$aster->build();
# Let print move clear
# $aster->remove_token_iter();
# dbgm $aster;
$aster->display();