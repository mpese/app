xquery version "3.1";

module namespace test-text = "http://mpese.ac.uk/corpus/text/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/'  at '../modules/mpese-corpus-text.xqm';

(: Test title with all details available :)
declare %test:assertEquals("Letters to the Heads of Cambridge Colleges (June 1626)") function test-text:title-with-data() {

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
        mpese-text:title($doc)

};

(: Test title with no title provided but with a date  :)
declare %test:assertEquals("Untitled (June 1626)") function test-text:result-title-missing-title() {

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
        mpese-text:title($doc)

};

(: Test title with no title provided but with a date  :)
declare %test:assertEquals("Untitled (No date)") function test-text:result-title-missing-title-date() {

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
        mpese-text:title($doc)

};

declare %test:assertXPath('count($result) eq 1') function test-text:one-author() {

        let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:fileDesc>
                            <tei:titleStmt>
                                <tei:author>
                                    <tei:persName corresp="../people/people.xml#P0026">Sir John Bramston the Elder</tei:persName>
                                </tei:author>
                            </tei:titleStmt>
                        </tei:fileDesc>
                    </tei:teiHeader>
                </tei:TEI>

        return

            mpese-text:authors($doc)

};

declare %test:assertXPath('count($result) eq 2') function test-text:two-author() {

        let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:fileDesc>
                            <tei:titleStmt>
                                <tei:author>
                                    <tei:persName corresp="../people/people.xml#P0026">Sir John Bramston the Elder</tei:persName>
                                </tei:author>
                                <tei:author>
                                    <tei:persName corresp="../people/people.xml#P0027">William Noy</tei:persName>
                                </tei:author>
                            </tei:titleStmt>
                        </tei:fileDesc>
                    </tei:teiHeader>
                </tei:TEI>

        return

            mpese-text:authors($doc)
};

declare %test:assertXPath('count($result) eq 3') function test-text:three-author() {

        let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:fileDesc>
                            <tei:titleStmt>
                                <tei:author>
                                    <tei:persName corresp="../people/people.xml#P0026">Sir John Bramston the Elder</tei:persName>
                                </tei:author>
                                <tei:author>
                                    <tei:persName corresp="../people/people.xml#P0027">William Noy</tei:persName>
                                </tei:author>
                                <tei:author>
                                    <tei:persName corresp="../people/people.xml#P0028">Sir Henry Calthorpe</tei:persName>
                                </tei:author>
                            </tei:titleStmt>
                        </tei:fileDesc>
                    </tei:teiHeader>
                </tei:TEI>

        return

            mpese-text:authors($doc)
};

(: Test getting the MSS URI for an include - normal :)
declare %test:assertEquals('/db/mpese/tei/corpus/mss/BLAddMS35331.xml') function test-text:mss-details-uri() {

    let $inc := <xi:include href="../mss/BLAddMS35331.xml" xpointer="BL_Add_MS_35331"/>

    return
        mpese-text:mss-details-uri($inc)
};

(: Test getting the MSS URI for an include - missing attributes :)
declare %test:assertEquals('') function test-text:mss-details-uri2() {

    let $inc := <xi:include />

    return
        mpese-text:mss-details-uri($inc)
};

(: Test getting the MSS URI for an include - empty element :)
declare %test:assertEquals('') function test-text:mss-details-uri3() {
    mpese-text:mss-details-uri(())
};

declare %test:assertXPath("$result//*:idno/string() eq 'MS 35331'") function test-text:mss-details-include() {

    let $inc := <xi:include href="../mss/BLAddMS35331.xml" xpointer="BL_Add_MS_35331"/>

    return
        mpese-text:mss-details-include($inc)
};


declare %test:assertXPath("$result//*:idno/string() eq 'MS 35331'") function test-text:mss-details() {
    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:sourceDesc>
                            <tei:msDesc corresp="../mss/BLAddMS35331.xml">
                                <xi:include href="../mss/BLAddMS35331.xml" xpointer="BL_Add_MS_35331"/>
                            </tei:msDesc>
                        </tei:sourceDesc>
                    </tei:teiHeader>
                </tei:TEI>
    return
        mpese-text:mss-details($doc)
};

(: test querying for text-type keywords :)
declare %test:assertXPath("fn:count($result) eq 1") function test-text:keywords-text-type() {
    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:profileDesc>
                            <tei:textClass>
                                <tei:keywords n="text-type">
                                    <tei:term>legal argument</tei:term>
                                </tei:keywords>
                            </tei:textClass>
                        </tei:profileDesc>
                    </tei:teiHeader>
                </tei:TEI>

    return
        mpese-text:keywords-text-type($doc)
};

(: text querying for topic keywords :)
declare %test:assertXPath("fn:count($result) eq 2") function test-text:keywords-topic() {
    let $doc := <tei:TEI>
                    <tei:teiHeader>
                      <tei:profileDesc>
                         <tei:textClass>
                            <tei:keywords n="topic-keyword">
                               <tei:term>habeas corpus</tei:term>
                               <tei:term>bail</tei:term>
                            </tei:keywords>
                         </tei:textClass>
                      </tei:profileDesc>
                   </tei:teiHeader>
                </tei:TEI>

    return
        mpese-text:keywords-topic($doc)
};

(: check the transform; just check we have multple p tags :)
declare %test:assertXPath("count($result//p) > 0") function test-text:text-body() {

    let $doc := doc('/db/mpese/tei/corpus/texts/HabeasCorpus1627.xml')

    return
        mpese-text:text-body($doc)
};


(: Test the formatting of with 1 author :)
declare %test:assertXPath("fn:count($result//a[@href]) eq 1") function test-text:label-one-author() {
    let $authors := <tei:author corresp="../people/people.xml#P0001">George Abbot</tei:author>
    return
        mpese-text:author-label($authors, true())
};

(: Test the formatting of with 1 author - no link :)
declare %test:assertXPath("fn:count($result//a[@href]) eq 1")
%test:assertXPath("fn:count($result//span) eq 1")
function test-text:label-one-author-no-link() {
    let $authors := <tei:author corresp="../people/people.xml#P0001">George Abbot</tei:author>
    return
        mpese-text:author-label($authors, true())
};

(: Test the formatting of with 2 authors :)
declare %test:assertXPath("fn:count($result//a[@href]) eq 2") function test-text:label-two-authors() {
    let $authors := (<tei:author  corresp="../people/people.xml#P0001">George Abbot</tei:author>,
        <tei:author corresp="../people/people.xml#P0002">James VI/I</tei:author>)
    return
        mpese-text:author-label($authors, true())
};

(: Test the formatting of with 2 authors - no link :)
declare %test:assertXPath("fn:count($result//a[@href]) eq 0") %test:assertXPath("fn:count($result//span) eq 2")
function test-text:label-two-authors-no-link() {
    let $authors := (<tei:author  corresp="../people/people.xml#P0001">George Abbot</tei:author>,
        <tei:author corresp="../people/people.xml#P0002">James VI/I</tei:author>)
    return
        mpese-text:author-label($authors, false())
};

(: Test the formatting of with 3 authors :)
declare %test:assertXPath("fn:count($result//a[@href]) eq 3") %test:assertXPath("fn:count($result//span) eq 3")
function test-text:label-many-authors() {
    let $authors := (<tei:author corresp="../people/people.xml#P0001">Charles I</tei:author>,
                     <tei:author corresp="../people/people.xml#P0002">Thomas Howard, 1st Earl of Berkshire</tei:author>,
                     <tei:author corresp="../people/people.xml#P0003">George Villiers, 1st Duke of Buckingham</tei:author>)
    return
        mpese-text:author-label($authors, true())
};

(: Test the formatting of with 3 authors - no linl:)
declare %test:assertXPath("fn:count($result//a[@href]) eq 0") %test:assertXPath("fn:count($result//span) eq 3")
function test-text:label-many-authors-no-link() {
    let $authors := (<tei:author corresp="../people/people.xml#P0001">Charles I</tei:author>,
                     <tei:author corresp="../people/people.xml#P0002">Thomas Howard, 1st Earl of Berkshire</tei:author>,
                     <tei:author corresp="../people/people.xml#P0003">George Villiers, 1st Duke of Buckingham</tei:author>)
    return
        mpese-text:author-label($authors, false())
};

declare %test:assertXPath("fn:count($result//a[@href]) eq 1") function test-text:person-with-attr-link() {
    let $person := <tei:author>
                        <tei:persName corresp="../people/people.xml#P0026">Sir John Bramston the Elder</tei:persName>
                   </tei:author>
    return
        mpese-text:person($person, true())
};

declare %test:assertXPath("fn:count($result//a[@href]) eq 0") function test-text:person-with-attr-no-link() {
    let $person := <tei:author>
                        <tei:persName corresp="../people/people.xml#P0026">Sir John Bramston the Elder</tei:persName>
                   </tei:author>
    return
        mpese-text:person($person, false())
};

declare %test:assertXPath("fn:count($result//a[@href]) eq 0") function test-text:person-without-attr() {
    let $person := <tei:author>
                        <tei:persName>Sir John Bramston the Elder</tei:persName>
                   </tei:author>
    return
        mpese-text:person($person, true())
};