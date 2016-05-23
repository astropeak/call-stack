package Aspk::Debug;
use Filter::Simple;
use File::Basename;
use Exporter;

use Scalar::Util qw(reftype);

@ISA=qw(Exporter);
@EXPORT_OK=qw(print_obj dbg_current_level);

my $dbg_current_level= 4;

my $objs = {};
sub{
    print "FFFFF";
}
sub print_call_stack {
    my $i = 2;
    my $objs = {};
    my @rst;
    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($i++);

    sub inline_sub{
        print "I am a inline sub";
    }

    $filename = my_basename($filename, 2);
    unshift @rst, [$filename, $line, $subroutine];
    while ($subroutine ne "") {
        ($package, $filename, $line, $subroutine, $hasargs,
         $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($i++);

        $filename = my_basename($filename, 2);
        unshift @rst, [$filename, $line, $subroutine];
    }
}

