#!/bin/bash

pushd ../aspk-code-base
git checkout ./perl/Aspk/FileCharIterator.pm
popd
perl main.pl ../aspk-code-base/perl/Aspk/FileCharIterator.pm
mv add_trace_FileCharIterator.pm ../aspk-code-base/perl/Aspk/FileCharIterator.pm
echo "\n1;\n" >> ../aspk-code-base/perl/Aspk/FileCharIterator.pm
perl main.pl test.pl
