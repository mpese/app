xquery version "3.1";

module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace transform = 'http://exist-db.org/xquery/transform';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';

(: title of the text or 'untitled' :)
declare function mpese-text:title($text) {
    let $title := fn:doc($text)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
    return
        if (not(functx:all-whitespace($title))) then
            $title
        else
            fn:string('Untitled')
};

(: text type keywords :)
declare function mpese-text:keywords-text-type($text) {
    fn:doc($text)/tei:TEI/tei:teiHeader/tei:profileDesc/tei:textClass/tei:keywords[@n='text-type']/tei:term
};

(: text type keywords :)
declare function mpese-text:keywords-topic($text) {
    fn:doc($text)/tei:TEI/tei:teiHeader/tei:profileDesc/tei:textClass/tei:keywords[@n='topic-keyword']/tei:term
};

(: display the text (delegate to an xsl file) :)
declare function mpese-text:text-body($text) {
    let $input := doc($text)
    let $xsl := doc('corpus-text-html.xsl')
    return
        transform:transform($input, $xsl, ())
};