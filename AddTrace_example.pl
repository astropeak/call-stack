use AddTrace;

# my $at = AddTrace->new('test.pl', 'add_trace_test.pl');
my $at = AddTrace->new('Memoize.pm', 'MemoizeAT.pm');
$at->build();
# $at->display();