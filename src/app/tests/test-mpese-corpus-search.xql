xquery version "3.0";

module namespace test-search = "http://mpese.ac.uk/corpus/search/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";

import module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/'  at '../modules/mpese-corpus-search.xqm';

declare %test:arg("page", 1) %test:arg("num", 10) %test:assertEquals(1)
function test-search:seq-start-page-1($page as xs:integer, $num as xs:integer) as xs:integer {
    mpese-search:seq-start($page, $num)
};

declare %test:arg("page", 2) %test:arg("num", 10) %test:assertEquals(11)
function test-search:seq-start-page-2($page as xs:integer, $num as xs:integer) as xs:integer {
    mpese-search:seq-start($page, $num)
};
