xquery version "3.1";

module namespace test-text = "http://mpese.ac.uk/corpus/text/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at '../modules/config.xqm';
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

(: check we get a date :)
declare %test:assertXPath("$result eq '22 November 1627'") function test-text:creation-date() {
    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:profileDesc>
                            <tei:creation>
                                <tei:date when="1627-11-22">22 November 1627</tei:date>
                                <tei:placeName corresp="../places/places.xml#PL0010">Court of King's Bench</tei:placeName>
                            </tei:creation>
                        </tei:profileDesc>
                    </tei:teiHeader>
                </tei:TEI>
    return
        mpese-text:creation-date($doc)
};

(: check we get a creation place :)
declare %test:assertXPath("contains($result/string(), 'Court of King')") function test-text:creation-place() {
    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:profileDesc>
                            <tei:creation>
                                <tei:date when="1627-11-22">22 November 1627</tei:date>
                                <tei:placeName corresp="../places/places.xml#PL0010">Court of King's Bench</tei:placeName>
                            </tei:creation>
                            <tei:langUsage>
                                <tei:language ident="EN">English</tei:language>
                                <tei:language ident="LA">Latin</tei:language>
                            </tei:langUsage>
                        </tei:profileDesc>
                    </tei:teiHeader>
                </tei:TEI>
    return
        mpese-text:creation-place($doc)
};

(: check we get a list of languages :)
declare %test:assertXPath("contains($result/string(), 'English')")
        %test:assertXPath("contains($result/string(), 'Latin')") function test-text:languages() {
    let $doc := <tei:TEI>
                    <tei:teiHeader>
                        <tei:profileDesc>
                            <tei:creation>
                                <tei:date when="1627-11-22">22 November 1627</tei:date>
                                <tei:placeName corresp="../places/places.xml#PL0010">Court of King's Bench</tei:placeName>
                            </tei:creation>
                            <tei:langUsage>
                                <tei:language ident="EN">English</tei:language>
                                <tei:language ident="LA">Latin</tei:language>
                            </tei:langUsage>
                        </tei:profileDesc>
                    </tei:teiHeader>
                </tei:TEI>
    return
        mpese-text:languages($doc)
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

declare %test:assertXPath("count($result) > 1") function test-text:witness-list() {
    let $doc := doc($config:mpese-tei-corpus-texts || '/HabeasCorpus1627.xml')
    return mpese-text:witnesses-includes($doc)
};

(: check we get an author from a bibliography :)
declare %test:assertXPath("contains($result, 'J[ohn] M[ilton]')") function test-text:bibl-author() {

    let $bibl := <tei:bibl>
                    <tei:author role="signatory">
                        <tei:persName corresp="../people/people.xml#P0060">
                            <tei:forename>J[ohn]</tei:forename>
                            <tei:surname>M[ilton]</tei:surname>
                        </tei:persName>
                    </tei:author>
                </tei:bibl>

    return mpese-text:bibl-author($bibl)
};

(: check we get an author from a bibliography :)
declare %test:assertEmpty function test-text:bibl-no-author() {

    let $bibl := <tei:bibl/>

    return mpese-text:bibl-author($bibl)
};

(: check we get a title from a bibliography :)
declare %test:assertXPath("<em>Newes from Hell, Rome and the Inns of Court</em>") function test-text:bibl-title() {

    let $bibl := <tei:bibl>
                    <tei:title>Newes from Hell, Rome and the Inns of Court</tei:title>
                 </tei:bibl>

    return mpese-text:bibl-title($bibl)
};

(: no title bibliography :)
declare %test:assertEmpty function test-text:bibl-no-title() {

    let $bibl := <tei:bibl/>

    return mpese-text:bibl-title($bibl)
};

(: full publication details :)
declare %test:assertEquals("(London, 1641)")function test-text:bibl-pub-full() {
    let $bibl := <tei:bibl>
                   <tei:date when="1641">1641</tei:date>
                   <tei:pubPlace>London</tei:pubPlace>
                 </tei:bibl>
    return mpese-text:bibl-pub($bibl)
};

(: publication date only :)
declare %test:assertEquals("(1641)")function test-text:bibl-pub-date() {
    let $bibl := <tei:bibl>
                   <tei:date when="1641">1641</tei:date>
                 </tei:bibl>
    return mpese-text:bibl-pub($bibl)
};

(: publication place details :)
declare %test:assertEquals("(London)")function test-text:bibl-pub-place() {
    let $bibl := <tei:bibl>
                   <tei:pubPlace>London</tei:pubPlace>
                 </tei:bibl>
    return mpese-text:bibl-pub($bibl)
};

(: no publication details :)
declare %test:assertEquals("") function test-text:bibl-pub-empty() {
    let $bibl := <tei:bibl/>
    return mpese-text:bibl-pub($bibl)
};

(: full idno details :)
declare %test:assertEquals("[Wing M42A]")function test-text:bibl-idno-full() {
    let $bibl := <tei:bibl>
                    <tei:idno type="Wing">M42A</tei:idno>
                 </tei:bibl>
    return mpese-text:bibl-idno($bibl)
};

(: idno with no type :)
declare %test:assertEquals("[M42A]")function test-text:bibl-idno-no-type() {
    let $bibl := <tei:bibl>
                   <tei:idno>M42A</tei:idno>
                 </tei:bibl>
    return mpese-text:bibl-idno($bibl)
};

(: no idno :)
declare %test:assertEquals("") function test-text:bibl-idno-empty() {
    let $bibl := <tei:bibl/>
    return mpese-text:bibl-idno($bibl)
};


declare %test:assertTrue function test-text:sameValueInScope-true() {
    let $scope := <tei:biblScope unit="page" from="8" to="8"></tei:biblScope>
    return mpese-text:sameBiblScopeVal($scope)
};

declare %test:assertFalse function test-text:sameValueInScope-false() {
    let $scope := <tei:biblScope unit="page" from="8" to="10">8-10</tei:biblScope>
    return mpese-text:sameBiblScopeVal($scope)
};


declare
%test:arg('type', 'page') %test:arg('plural', 'true') %test:assertEquals('pp. ')
%test:arg('type', 'page') %test:arg('plural', 'false') %test:assertEquals('p. ')
%test:arg('type', 'sigs') %test:arg('plural', 'true') %test:assertEquals('sigs. ')
%test:arg('type', 'sigs') %test:arg('plural', 'false') %test:assertEquals('sig. ')
function test-text:bibloScopePrefix($type as xs:string, $plural as xs:boolean) {
    mpese-text:bibloScopePrefix($type, $plural)
};

(: ---------- test template method functions ----------:)

(: Check we get the text and mss and add it to the model:)
declare %test:assertXPath("count($result?text//*:title) > 0")
        %test:assertXPath("$result?mss//*:idno eq 'MS 35331'") function test-text:text() {

    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'

    return mpese-text:text($node, $model, $text)

};

(: check expected sample data in the author and title :)
declare %test:assertXPath("contains($result/string(), 'Sir John Bramston the Elder') eq true()")
        %test:assertXPath("contains($result/string(), 'The Arguments Made in the Greate Case of Habeas Corpus (22 November 1627)') eq true()")
function test-text:author-title() {

    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return
        mpese-text:author-title($node, $map)
};

(: check expected sample data manuscript details :)
declare %test:assertXPath("contains($result/string(), 'British Library, Additional, MS 35331') eq true()")
function test-text:mss() {

    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return
        mpese-text:mss($node, $map)
};

(: check expected sample data in mss name :)
declare %test:assertXPath("contains($result/string(), 'Diary of Walter Yonge') eq true()")
function test-text:mss-name() {

    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return
        mpese-text:mss-name($node, $map)
};

declare
%test:assertXPath("contains($result/string(), 'British Library, Additional, MS 35331') eq true()")
%test:assertXPath("contains($result/string(), 'Diary of Walter Yonge') eq true()")
function test-text:mss-name-full() {
    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return
        mpese-text:mss-name-full($node, $map)
};

(: check expected sample data in mss name :)
declare %test:assertXPath("count($result//div) > 0")
function test-text:image() {

    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return
        mpese-text:image($node, $map)
};

(: check sample data on the output :)
declare %test:assertXPath("count($result//p) > 0")
function test-text:transcript() {

    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return
        mpese-text:transcript($node, $map)
};

(: test we get a list of witnesses :)
declare %test:assertXPath("count($result//li) > 0")
function test-text:witnesses() {
    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return mpese-text:witnesses($node, $map)
};

(: test we get a list of authors :)
declare %test:assertXPath("count($result//li) > 0")
function test-text:author-list() {
    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return mpese-text:author-list($node, $map)
};

(: test we get a list of text types :)
declare %test:assertXPath("count($result//li) > 0")
function test-text:text-type() {
    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return mpese-text:text-type($node, $map)
};

(: test we get a list of topics :)
declare %test:assertXPath("count($result//li) > 0")
function test-text:text-topic() {
    let $node := <test></test>
    let $model := map {}
    let $text := 'HabeasCorpus1627.xml'
    let $map := mpese-text:text($node, $model, $text)
    return mpese-text:text-topic($node, $map)
};