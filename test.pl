package Aspk::Debug;
use Filter::Simple;
use File::Basename;
use Exporter;

use Scalar::Util qw(reftype);

@ISA=qw(Exporter);
@EXPORT_OK=qw(print_obj dbg_current_level);

my $dbg_current_level= 4;

my $a = qr/\w*/abc;
my $b="AAAA";
"AAAA" =~ s/A/B/m;
$b = "CCCC" if $b =~m/BB/m;
my $objs = {};
sub{
    print "FFFFF";
    my $str="12\"3's\
aa\n";
    my $str1='aa sub hah {ab;}b"cc\n"\t\x';
}
sub print_call_stack {
    my $i = 2;
    my $objs = {};
    my @rst;
    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($i++);

    sub inline_sub{
        print "I am a inline sub";
        return $a+$b+$c*123;
    }
    # a comment
    $filename = my_basename($filename, 2);
    if ($filename) {
        return 2;
    }
    unshift @rst, [$filename, $line, $subroutine];
    while ($subroutine ne "") { #another { } comment sub aaa { }.
        ($package, $filename, $line, $subroutine, $hasargs,
         $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($i++);

        $filename = my_basename($filename, 2);
        unshift @rst, [$filename, $line, $subroutine];
        return;
    }

    return $self->get->{"aaaa", {a=>'BC', {8, 99}},"DD"};

    return sub{my $a="AAAA";
               return $a;};
}

=aaaa


    aaabbccc





    sssddd
    =cut ABC

    print "end\n";
=cut

sub AA () {
    my $b;
    if (1) {
        return $a = $b->{name}->{type1}
    }

    if (2) {
        "BBBB";
        return $a = $b->{name}->{type1}
    } else {
        "DDDD"
    }
    return $a->{name}->{type};
}
sub BB (&a&) {
    $a->{name}->{type}
}

sub CC {
    if (1) {
        $a->{name}->{type}
    }
    elsif ($aaabbbcc) {
        $b->{'elsif'}->{type}
    }
    # elsif ($aaabbbcc) {
    #     $b->{'elsif'}->{type}
    # }
    else {
        $b->{'else'}->{type}
    }

    $c->{A}{B};
}

aaa;
bbb;