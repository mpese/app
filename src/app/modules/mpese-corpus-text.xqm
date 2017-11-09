(:
 : Module for handling the display of a pamphlet text for the public website.
 :
 : @author Mike Jones (mike.a.jones@bristol.ac.uk)
 :)
xquery version "3.1";

module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace transform = 'http://exist-db.org/xquery/transform';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';
import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";

(:~
    Provide the title of the text or 'untitled'.

    @param $uri      the URI of the text document.
    @return the title of the text of 'untitled'
 :)
declare function mpese-text:title($uri as xs:string) as xs:string {
    let $title := fn:doc($uri)//tei:fileDesc/tei:titleStmt/tei:title/text()
    return
        if (not(functx:all-whitespace($title))) then
            $title
        else
            fn:string('Untitled')
};

(:~
    The list of authors associated with a text.
    Note: some might be signatories and not actually authors.

    @param $uri      the URI of the text document.
    @return a list of author elements.
 :)
declare function mpese-text:authors($uri as xs:string) as element()* {
    fn:doc($uri)//tei:fileDesc/tei:titleStmt/tei:author
};

(:~
    Get the mss details via the Xinclude.

    @param $include     the Xinclude element with details of the MS.
:)
declare function mpese-text:mss-details-include($include as element()) as element() {

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
    let $include := doc($text)//tei:sourceDesc/tei:msDesc/xi:include

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

declare function mpese-text:mss-details-label($mss) {
    if (count($mss/*) > 0) then
        concat($mss/tei:repository, ', ', $mss/tei:collection, ', ', $mss/tei:idno)
    else
        "No manuscript details."
};

(: ---------- TEMPLATE FUNCTIONS ----------- :)

(: Adds the full URI of the text and the basic details about the manuscript to the model, so that it can be
   used by subsequent calls :)
declare function mpese-text:text($node as node (), $model as map (*), $text as xs:string) {

    let $text := concat($config:mpese-tei-corpus-texts, '/', $text)
    let $mss := mpese-text:mss-details($text)
    return
        map { "text" := $text, "mss" := $mss}
};

(: author and title :)
declare %templates:wrap function mpese-text:author-title($node as node (), $model as map (*), $text as xs:string) {
    (mpese-text:author-label($model('text')), '&apos;', mpese-text:title($model('text')), '&apos;')
};

(: basic mss details :)
declare %templates:wrap function mpese-text:mss($node as node (), $model as map (*), $text as xs:string) {
    mpese-text:mss-details-label($model('mss'))
};

(: mss name :)
declare function mpese-text:mss-name($node as node (), $model as map (*)) {
    if (not(functx:has-empty-content($model('mss')//tei:msName))) then
        <p>{$model('mss')//tei:msName/string()}</p>
    else
        ""
};


(: the image :)
declare function mpese-text:image($node as node (), $model as map (*), $text as xs:string) {
    let $images := fn:doc($model('text'))//tei:pb[@facs]/@facs/string()
    let $distinct := fn:string-join(distinct-values($images), ';')
    return
        if ($distinct) then
            <div id='mss-images' data-images="{$distinct}">
                <div id="openseadragon"></div>
            </div>
        else
            <div class="well well-lg"><p class="text-center font-weight-bold">No image</p></div>
};

(: the transcript :)
declare function mpese-text:transcript($node as node (), $model as map (*), $text as xs:string) {
    mpese-text:text-body($model('text'))
};