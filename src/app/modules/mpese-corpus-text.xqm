xquery version "3.1";

module namespace mpese-text = "http://mpese.rit.bris.ac.uk/corpus/text/";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";

declare function mpese-text:title($text) {
    let $title := fn:doc($text)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
    return
        if (not(functx:all-whitespace($title))) then
            $title
        else
            fn:string('Untitled')
};