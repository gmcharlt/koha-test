#!/usr/bin/perl
#
# This Koha test module is a stub!  
# Add more tests here!!!

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
        use_ok('C4::ClassSortRoutine::LCC');
}

#Obvious cases
is(C4::ClassSortRoutine::LCC::get_class_sort_key(), "", "No arguments returns an empty string");
is(C4::ClassSortRoutine::LCC::get_class_sort_key('a','b'), "A_B", "Arguments 'a','b' return 'A_B'");

#spaces in arguements
is(C4::ClassSortRoutine::LCC::get_class_sort_key(' ','b'), "B_", "Arguments ' ','b' return 'B_'");
is(C4::ClassSortRoutine::LCC::get_class_sort_key('a',' '), "A_", "Arguments 'a',' ' return 'A_'");
is(C4::ClassSortRoutine::LCC::get_class_sort_key(' ','    '), "", "Arguments ' ','    ' return ''");

#'funky cases' based on regex in code
is(C4::ClassSortRoutine::LCC::get_class_sort_key('.','b'), "_B", "Arguments '.','b' return '_B'");
is(C4::ClassSortRoutine::LCC::get_class_sort_key('....','........'), "_______", "Arguments '....','........' return '_______'");
is(C4::ClassSortRoutine::LCC::get_class_sort_key('.','.'), "__", "Arguments '.','.' return '__'");

# list of example call numbers -- these
# are intentionally in the _reverse_ of
# the correct sort order
my @call_numbers = (
    'SB410.9 .P26 1993',
    'SB410.A26 I75 2000',
);

my @sorted_call_numbers = map { $_->{call_number} }
                          sort { $a->{sortkey} cmp $b->{sortkey} }
                          map { { call_number => $_, sortkey => C4::ClassSortRoutine::LCC::get_class_sort_key($_, '') } }
                          @call_numbers;
is_deeply(\@sorted_call_numbers, [ reverse @call_numbers ], 'LC call numbers sorted in correct order');
