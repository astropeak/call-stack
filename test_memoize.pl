use Memoize;

memoize fib;
sub fib {
    my $d = shift;
    print "Enter fib, $d\n";
    if ($d== 1 || $d==2){
        return 1;
    } else {
        return fib($d-1)+fib($d-2);
    }
}
$a=fib(4);
print "fib(4) result:$a\n";
$a=fib(4);
print "fib(4) result:$a\n";
