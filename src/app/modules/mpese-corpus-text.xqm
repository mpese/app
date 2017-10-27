xquery version "3.1";

module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace templates = "http://exist-db.org/xquery/templates";
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

(: mss details ... follow the yellow brick road :)
declare function mpese-text:mss-details-include($include) {

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

(: mss details ... follow the yellow brick road :)
declare function mpese-text:mss-details($text) {

    (: get the include :)
    let $include := doc($text)//tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/xi:include

    return
        mpese-text:mss-details-include($include)
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

(: ---------- HELPER FUNCTIONS FOR RENDERING CONTENT ----------- :)

(: get a person and link to their details :)
declare function mpese-text:person($person) {
    let $corresp := $person//@corresp/string()
    return
        if (fn:string-length($corresp) > 0) then
            let $id := fn:tokenize($corresp, '#')[2]
            return fn:normalize-space($person/string())
        else
            fn:normalize-space($person/string())
};

(: authors of a text :)
declare function mpese-text:author-label($file) {
    let $authors := mpese-text:authors($file)
    let $auth_count := fn:count($authors)
    return
        if ($auth_count > 0) then
            if ($auth_count > 1) then
                for $author at $pos in $authors
                    return
                        if ($pos eq $auth_count) then
                            concat(' and ',  mpese-text:person($author), ', ')
                        else
                            concat(mpese-text:person($author), ', ')
            else
                if (fn:string-length($authors[1]/string()) > 0) then
                    concat(mpese-text:person($authors[1]), ', ')
                else
                    ""
        else
            ""
};

declare function mpese-text:mss-details-label($text) {
    let $mss := mpese-text:mss-details
    return
        concat($mss/tei:repository/string())
};

(: ---------- TEMPLATE FUNCTIONS ----------- :)

(: adds the full URI of the text to the map so that it can be used by following functions  -
 : the $text variable is passed in via the controller; it generates it from the requested
 : URL, which includes the name of the file :)
declare function mpese-text:text($node as node (), $model as map (*), $text as xs:string) {
    map { "text" := concat($config:mpese-tei-corpus-texts, '/', $text) }
};

(: author and title :)
declare %templates:wrap function mpese-text:author-title($node as node (), $model as map (*), $text as xs:string) {
    (mpese-text:author-label($model('text')), '&apos;', mpese-text:title($model('text')), '&apos;')
};

(: mss details :)


(: the image :)
declare function mpese-text:image($node as node (), $model as map (*), $text as xs:string) {
    <div><p>No image</p></div>
};

(: the transcript :)
declare function mpese-text:transcript($node as node (), $model as map (*), $text as xs:string) {
    mpese-text:text-body($model('text'))
};