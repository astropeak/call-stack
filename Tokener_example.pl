use Tokener;
use Aspk::Debug;

my $tk = Tokener->new('test.pl');
while (defined (my $t=$tk->get())) {
    dbgm $t;
}