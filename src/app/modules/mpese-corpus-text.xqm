xquery version "3.1";

module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace transform = 'http://exist-db.org/xquery/transform';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';
import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";

(: title of the text or 'untitled' :)
declare function mpese-text:title($text) {
    let $title := fn:doc($text)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
    return
        if (not(functx:all-whitespace($title))) then
            $title
        else
            fn:string('Untitled')
};


declare function mpese-text:authors($text) {
    fn:doc($text)//tei:fileDesc/tei:titleStmt/tei:author
};

declare function mpese-text:mss-details($text) {

    (: get the include :)
    let $include := doc($text)//tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/xi:include

    (: get the path and id :)
    let $include_url := $include/@href/string()
    let $include_id := $include/@xpointer/string()

    (: get the full path for the mss :)
    let $mss := if (fn:starts-with($include_url, '../')) then fn:substring($include_url, 3) else $include_url
    let $mss_full := concat($config:mpese-tei-corpus, $mss)

    (: return the node :)
    return
        doc($mss_full)//*[@xml:id=$include_id]
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