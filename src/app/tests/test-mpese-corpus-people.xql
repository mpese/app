xquery version "3.1";

module namespace test-person = "http://mpese.ac.uk/corpus/person/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at '../modules/config.xqm';
import module namespace mpese-person = 'http://mpese.rit.bris.ac.uk/corpus/person/'  at '../modules/mpese-corpus-person.xqm';


(: test we get a list of topics :)
declare %test:assertXPath("deep-equal($result, <h1>William Herbert 3rd Earl of Pembroke</h1>)")
function test-person:text-topic() {
    let $node := <test></test>
    let $person := <tei:person xml:id="P0079" sex="M">
                        <tei:persName>
                            <tei:forename>William</tei:forename>
                            <tei:surname>Herbert</tei:surname>
                            <tei:roleName>3rd Earl of Pembroke</tei:roleName>
                        </tei:persName>
                    </tei:person>

    let $map := map { 'person': $person }
    return mpese-person:title($node, $map)
};