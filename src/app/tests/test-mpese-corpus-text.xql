xquery version "3.1";

module namespace test-text = "http://mpese.ac.uk/corpus/text/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/'  at '../modules/mpese-corpus-text.xqm';

(: Test title with all details available :)
declare %test:assertEquals("Letters to the Heads of Cambridge Colleges (June 1626)") function test-text:result-title() {

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