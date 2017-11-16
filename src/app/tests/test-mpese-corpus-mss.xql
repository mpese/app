xquery version "3.1";

module namespace test-mss = "http://mpese.ac.uk/corpus/mss/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/'  at '../modules/mpese-corpus-mss.xqm';


declare %test:assertEquals('British Library, Additional, MS 35331')function test-mss:ident-label() {
    let $mss := <tei:msIdentifier xml:id="BL_Add_MS_35331">
                    <tei:country>United Kingdom</tei:country>
                    <tei:settlement>London</tei:settlement>
                    <tei:repository>British Library</tei:repository>
                    <tei:collection>Additional</tei:collection>
                    <tei:idno>MS 35331</tei:idno>
                    <tei:msName>Diary of Walter Yonge</tei:msName>
                 </tei:msIdentifier>
    return
        mpese-mss:ident-label($mss)
};


declare %test:assertEquals('No manuscript details.')function test-mss:mss-details-label-empty() {
    mpese-mss:ident-label(())
};

(: Check we get the text and mss and add it to the model:)
declare %test:assertXPath("count($result?mss//*:title) > 0") function test-mss:mss() {

    let $node := <test></test>
    let $model := map {}
    let $mss := 'BLAddMS35331.xml'

    return mpese-mss:mss($node, $model, $mss)
};

(: Check we get the text and mss and add it to the model:)
declare %test:assertXPath("deep-equal($result, <h2>British Library, Additional, MS 35331</h2>)")
function test-mss:mss-ident() {

    let $node := <test></test>
    let $model := map {}
    let $mss := 'BLAddMS35331.xml'
    let $map := mpese-mss:mss($node, $model, $mss)

    return mpese-mss:mss-ident($node, $map)
};