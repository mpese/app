xquery version "3.1";

module namespace test-search = "http://mpese.ac.uk/corpus/search/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/'  at '../modules/mpese-corpus-search.xqm';


(: Test the calculation of the starts of a results sequence, based on the selected page :)
declare
%test:arg("page", 1) %test:arg("num", 10) %test:assertEquals(1)
%test:arg("page", 2) %test:arg("num", 10) %test:assertEquals(11)
%test:arg("page", 6) %test:arg("num", 10) %test:assertEquals(51)
function test-search:seq-start-page($page as xs:integer, $num as xs:integer) as xs:integer {
    mpese-search:seq-start($page, $num)
};


(: Test the calculation of the number of pages based on the result size :)
declare
%test:arg("total", 1) %test:arg("num", 10) %test:assertEquals(1)
%test:arg("total", 20) %test:arg("num", 10) %test:assertEquals(2)
%test:arg("total", 53) %test:arg("num", 10) %test:assertEquals(6)
function test-search:pages-results-1($total as xs:integer, $num as xs:integer) as xs:integer {
    mpese-search:pages-total($total, $num)
};

(: Test searching all titles returns results :)
declare %test:assertTrue function test-search:default-all() {
    let $results := mpese-search:all()
    return
        fn:count($results) > 0
};

(: Test searching a keyword returns results :)
declare %test:assertTrue function test-search:search() {
    let $results := mpese-search:search("petition")
    return
        fn:count($results) > 0
};


(: Tests getting a subset of results for paginaation :)
declare %test:assertTrue function test-search:paginate-results() {
    let $seq := (<result>1</result>,<result>2</result>,<result>3</result>,<result>4</result>,
                <result>5</result>,<result>6</result>, <result>7</result>, <result>8</result>,
                <result>9</result>, <result>10</result>)
    let $results := mpese-search:paginate-results($seq, 2, 5)
    return ($results[1]/text() eq '2' and $results[5]/text() eq '6')
};