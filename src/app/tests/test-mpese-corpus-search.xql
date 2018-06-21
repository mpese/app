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

(: Test filtering out texts that aren't privileged :)
(:declare %test:assertTrue function test-search:search-filtered() {:)
    (:let $results := mpese-search:search("sackville challenges"):)
    (:return:)
        (:fn:count($results) eq 1:)
(:};:)


(: Tests getting a subset of results for paginaation :)
(:declare %test:assertTrue function test-search:paginate-results() {:)
    (:let $seq := <results><result>1</result>,<result>2</result>,<result>3</result>,<result>4</result>,:)
                (:<result>5</result>,<result>6</result>, <result>7</result>, <result>8</result>,:)
                (:<result>9</result>, <result>10</result></results>:)
    (:let $results := mpese-search:paginate-results($seq, 2, 5):)
    (:return ($results/result[1]/text() eq '2' and $results/result/[5]/text() eq '6'):)
(:};:)

(: we should have languages :)
declare %test:assertXPath("count($result) > 0")
function test-search:languages() {
    mpese-search:languages()
};

(: we should have repositories :)
declare %test:assertXPath("count($result) > 0")
function test-search:repositories() {
    mpese-search:repositories()
};


(: ------- message based on results ------- :)

(: no results :)
declare %test:assertXPath("deep-equal($result, '0 texts available.')")
function test-search:results-message-0() {
    mpese-search:results-message(0)
};

(: one result :)
declare %test:assertXPath("deep-equal($result, '1 text available.')")
function test-search:results-message-1() {
    mpese-search:results-message(1)
};

(: many results :)
declare %test:assertXPath("deep-equal($result, '45 texts available.')")
function test-search:results-message-2() {
    mpese-search:results-message(45)
};


(: ------- test build query -----:)

(: nothing just creates a wild card - default view on loading the application / empty basic search:)
declare %test:assertXPath("deep-equal($result, <query><bool><wildcard>*</wildcard></bool></query>)")
function test-search:build-query-basic-1() {
    mpese-search:build-query((), (), ())
};

(: empty query creates wildcard :)
declare %test:assertXPath("deep-equal($result, <query><bool><wildcard>*</wildcard></bool></query>)")
function test-search:build-query-1() {
    mpese-search:build-query('', 'all', '')
};

(: empty query (lots of whitespace) creates wildcard :)
declare %test:assertXPath("deep-equal($result, <query><bool><wildcard>*</wildcard></bool></query>)")
function test-search:build-query-2() {
    mpese-search:build-query('', 'all', '')
};

(: keywords, all needed  :)
declare %test:assertXPath("deep-equal($result, <query><bool><term occur='must'>challenge</term><term occur='must'>courage</term></bool></query>)")
function test-search:build-query-3() {
    mpese-search:build-query('challenge courage', 'all', '')
};

(: keywords, any  :)
declare %test:assertXPath("deep-equal($result, <query><bool><term>challenge</term><term>courage</term></bool></query>)")
function test-search:build-query-4() {
    mpese-search:build-query('challenge courage', 'any', '')
};

(: keywords, any, including wildcard  :)
declare %test:assertXPath("deep-equal($result, <query><bool><term>challenge</term><wildcard>courage*</wildcard></bool></query>)")
function test-search:build-query-5() {
    mpese-search:build-query('challenge courage*', 'any', '')
};

(: phrase  :)
declare %test:assertXPath("deep-equal($result, <query><phrase>challenge courage</phrase></query>)")
function test-search:build-query-6() {
    mpese-search:build-query('challenge courage', 'phrase', '')
};

(: exclude  :)
declare %test:assertXPath("deep-equal($result, <query><bool><term>challenge</term><term occur='not'>courage</term></bool></query>)")
function test-search:build-query-7() {
    mpese-search:build-query('challenge', 'any', 'courage')
};