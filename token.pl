use Aspk::FileCharIterator;
use Aspk::Debug;

my @token, $current_other, $t;
my $fciter=Aspk::FileCharIterator->new('test.pl');

while (1) {
    # match a subname
    $t=$fciter->get('sub\s+\w*');
    # dbgm $t;
    if ($t ne '') {
        if ($current_other ne '') {
            push @token, {type=>other, value=>$current_other};
            $current_other='';
        }
        push @token, {type=>subname, value=>$t};
        next;
    }

    # match a { or }
    $t=$fciter->get('{|}');
    if ($t ne '') {
        if ($current_other ne '') {
            push @token, {type=>other, value=>$current_other};
            $current_other='';
        }
        push @token, {type=>literal, value=>$t};
        next;
    }

    # all other things
    $t=$fciter->get();
    # $current_other.=$t unless $t=~/\n/;
    # $current_other.=$t;

    last if ($t eq '');
};

dbgm \@token;