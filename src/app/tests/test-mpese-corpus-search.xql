xquery version "3.0";

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

(: Test the formatting of with 1 author :)
declare %test:assertEquals("George Abbot") function test-search:label-one-author() {
    let $authors := <author>George Abbot</author>
    return
        mpese-search:author-label($authors)
};

(: Test the formatting of with 2 authors :)
declare %test:assertEquals("George Abbot, and James VI/I") function test-search:label-two-authors() {
    let $authors := (<author>George Abbot</author>,<author>James VI/I</author>)
    return
        mpese-search:author-label($authors)
};

(: Test the formatting of with 3 authors :)
declare %test:assertEquals("Charles I, Thomas Howard, 1st Earl of Berkshire, and George Villiers, 1st Duke of Buckingham")
function test-search:label-many-authors() {
    let $authors := (<author>Charles I</author>, <author>Thomas Howard, 1st Earl of Berkshire</author>,
                     <author>George Villiers, 1st Duke of Buckingham</author>)
    return
        mpese-search:author-label($authors)
};

(: Test searching all titles returns results :)
declare %test:assertTrue function test-search:default-search() {
    let $results := mpese-search:search-title("*:*")
    return
        fn:count($results) > 0
};

(: Test searching a keyword returns results :)
declare %test:assertTrue function test-search:search() {
    let $results := mpese-search:search("petition")
    return
        fn:count($results) > 0
};

(: Test title with all details available :)
declare %test:assertEquals("Letters to the Heads of Cambridge Colleges (June 1626)") function test-search:result-title() {

    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:fileDesc>
                            <tei:titleStmt>
                                <tei:title>Letters to the Heads of Cambridge Colleges</tei:title>
                            </tei:titleStmt>
                        </tei:fileDesc>
                        <tei:profileDesc>
                            <tei:creation>
                                <tei:date>June 1626</tei:date>
                            </tei:creation>
                        </tei:profileDesc>
                    </tei:teiHeader>
                </tei:TEI>

    return
        mpese-search:result-title($doc)

};

(: Test title with no title provided but with a date  :)
declare %test:assertEquals("Untitled (June 1626)") function test-search:result-title-missing-title() {

    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:fileDesc>
                            <tei:titleStmt>
                                <tei:title/>
                            </tei:titleStmt>
                        </tei:fileDesc>
                        <tei:profileDesc>
                            <tei:creation>
                                <tei:date>June 1626</tei:date>
                            </tei:creation>
                        </tei:profileDesc>
                    </tei:teiHeader>
                </tei:TEI>

    return
        mpese-search:result-title($doc)

};

(: Test title with no title provided but with a date  :)
declare %test:assertEquals("Untitled (No date)") function test-search:result-title-missing-title-date() {

    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:fileDesc>
                            <tei:titleStmt>
                                <tei:title/>
                            </tei:titleStmt>
                        </tei:fileDesc>
                        <tei:profileDesc>
                            <tei:creation>
                                <tei:date/>
                            </tei:creation>
                        </tei:profileDesc>
                    </tei:teiHeader>
                </tei:TEI>

    return
        mpese-search:result-title($doc)

};

(: Tests getting a subset of results for paginaation :)
declare %test:assertTrue function test-search:paginate-results() {
    let $seq := (<result>1</result>,<result>2</result>,<result>3</result>,<result>4</result>,
                <result>5</result>,<result>6</result>, <result>7</result>, <result>8</result>,
                <result>9</result>, <result>10</result>)
    let $results := mpese-search:paginate-results($seq, 2, 5)
    return ($results[1]/text() eq '2' and $results[5]/text() eq '6')
};