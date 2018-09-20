xquery version "3.1";

module namespace test-mss = "http://mpese.ac.uk/corpus/mss/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/'  at '../modules/mpese-corpus-mss.xqm';


declare %test:assertEquals('British Library, Additional MS 35331')function test-mss:ident-label() {
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

declare %test:assertXPath("deep-equal($result, <span class='mss-item-person'><a href='../p/P0027.html'>William Noy</a></span>)")
function test-mss:person-with-link() {

    let $person := <tei:author><tei:persName corresp="../people/people.xml#P0027">William Noy</tei:persName></tei:author>
    return mpese-mss:person($person)
};


declare %test:assertXPath("deep-equal($result, <span class='mss-item-person'>William Noy</span>)")
function test-mss:person-without-link() {

    let $person := <tei:author><tei:persName>William Noy</tei:persName></tei:author>
    return mpese-mss:person($person)
};

(: --------- Test template functions ---------- :)

(: Check we get the text and mss and add it to the model:)
declare %test:assertXPath("deep-equal($result, <h1>British Library, Additional MS 35331</h1>)")
function test-mss:mss-ident() {

    let $node := <test></test>
    let $model := map {}
    let $mss := 'BLAddMS35331.xml'
    let $map := mpese-mss:mss($node, $model, $mss)

    return mpese-mss:mss-ident($node, $map)
};


(: Check we get the foliation details :)
declare %test:assertTrue("$result//div[@id='foliation-details]/p")
function test-mss:foliation() {
    let $node := <test></test>
    let $model := map {}
    let $mss := 'BLAddMS35331.xml'
    let $map := mpese-mss:mss($node, $model, $mss)

    return mpese-mss:foliation($node, $map)
};

(: Check we a list of 'hands' :)
declare %test:assertXPath("count($result//li) > 1")
function test-mss:hand-notes() {
    let $node := <test></test>
    let $model := map {}
    let $mss := 'BLAddMS35331.xml'
    let $map := mpese-mss:mss($node, $model, $mss)

    return mpese-mss:hand-notes($node, $map)
};

(: Check we get a list of MS items :)
declare %test:assertTrue("$result//div[@id='mss-history']")
function test-mss:history() {

    let $node := <test></test>
    let $model := map {}
    let $mss := 'BLAddMS35331.xml'
    let $map := mpese-mss:mss($node, $model, $mss)

    return mpese-mss:history($node, $map)
};

(: Check we get a list of MS items :)
declare %test:assertXPath("count($result//div[@class='mss-item']) > 3")
function test-mss:contents() {

    let $node := <test></test>
    let $model := map {}
    let $mss := 'BLAddMS35331.xml'
    let $map := mpese-mss:mss($node, $model, $mss)

    return mpese-mss:contents($node, $map)
};

