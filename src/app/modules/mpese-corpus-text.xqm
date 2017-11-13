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
 :   Provide the title of the text (with date) or 'untitled'.
 :
 :  @param $doc      the TEI/XML document.
 :  @return the title of the text of 'untitled'
 :)
declare function mpese-text:title($doc as element()) as xs:string {

    let $tmp_title := $doc//tei:fileDesc/tei:titleStmt/tei:title/string()
    let $tmp_date := $doc//tei:profileDesc/tei:creation/tei:date[1]/string()
    let $title := ( if (fn:string-length($tmp_title) > 0) then $tmp_title else fn:string('Untitled') )
    let $date  := ( if (fn:string-length($tmp_date) > 0) then $tmp_date else fn:string('No date') )
    return
        concat($title, ' (', $date, ')')
};

(:~
 :  The list of authors associated with a text.
 :  Note: some might be signatories and not actually authors.
 :
 :  @param $doc      the TEI/XML document.
 :  @return a list of author elements.
 :)
declare function mpese-text:authors($doc as element()) as element()* {
    $doc//tei:fileDesc/tei:titleStmt/tei:author
};

(:~
 :  We use an Xinclude to link a text to its MSS. This method constructs
 :  the URI of the MSS document.
 :
 :  @param $include     the Xinclude element with details of the MS.
 :)
declare function mpese-text:mss-details-uri($include as element()?) as xs:string {

    (: get the path and id :)
    let $include_url := $include/@href/string()

    return
        if (boolean($include_url) eq false()) then
            ""
    else
        (: get the full path for the mss :)
        let $mss := if (fn:starts-with($include_url, '../')) then fn:substring($include_url, 3) else $include_url
        let $mss_full := concat($config:mpese-tei-corpus, $mss)

        return $mss_full
};

(:~
 :  We use an Xinclude to link a text to its MSS. This method pulls the
 :  MSS details we are interested.
 :
 :  @param $include     the Xinclude element with details of the MS.
 :)
declare function mpese-text:mss-details-include($include as element()?) as element()? {

    (: get the URI of the MSS :)
    let $mss_full := mpese-text:mss-details-uri($include)

    (: get the id :)
    let $include_id := $include/@xpointer/string()

    return

        if (boolean($mss_full) and boolean($include_id)) then
            doc($mss_full)//*[@xml:id=$include_id]
        else
            ()
};

(:~
 : Get the MSS details for the TEI document.
 :
 :  @param $doc      the TEI/XML document.
 :)
declare function mpese-text:mss-details($doc) {

    (: get the include :)
    let $include := $doc//tei:sourceDesc/tei:msDesc/xi:include

    return
        mpese-text:mss-details-include($include)
};

(: text type keywords :)
declare function mpese-text:keywords-text-type($doc) {
    $doc//tei:profileDesc/tei:textClass/tei:keywords[@n='text-type']/tei:term
};

(: text type keywords :)
declare function mpese-text:keywords-topic($doc) {
    $doc//tei:profileDesc/tei:textClass/tei:keywords[@n='topic-keyword']/tei:term
};

(: display the text (delegate to an xsl file) :)
declare function mpese-text:text-body($text) {
    let $xsl := doc('corpus-text-html.xsl')
    return
        transform:transform($text, $xsl, ())
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

(:
:~
 : Recursive function to create a formatted string of authors for a text.
 :
 : @param $label - the current label
 : @param $authors - the current sequence of authors.
 : @returns a formatted label of authors.
:)
declare function mpese-text:author-label-r($label as xs:string, $authors as node()*) as xs:string {

    let $auth_count := fn:count($authors)
    return
        if ($auth_count eq 1) then
            $label || functx:trim($authors[1]/string())
        else if ($auth_count eq 2) then
            let $tmp_label := $label || functx:trim($authors[1]/string()) || ', and '
            let $tmp_authors := fn:subsequence($authors, 2)
            return
                mpese-text:author-label-r($tmp_label, $tmp_authors)
        else
            let $tmp_label := $label || functx:trim($authors[1]/string()) || ', '
            let $tmp_authors := fn:subsequence($authors, 2)
            return
                mpese-text:author-label-r($tmp_label, $tmp_authors)
};


(:
:~
 : Entry point for the recursive function to create a formatted string of authors for a text.
 :
 : @param $authors - the current sequence of authors.
 : @returns a formatted label of authors.
:)
declare function mpese-text:author-label($authors) {
    mpese-text:author-label-r("", $authors)
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

    let $doc := doc(concat($config:mpese-tei-corpus-texts, '/', $text))//tei:TEI
    let $mss := mpese-text:mss-details($doc)
    return
        map { "text" := $doc, "mss" := $mss}
};

(: author and title :)
declare %templates:wrap function mpese-text:author-title($node as node (), $model as map (*), $text as xs:string) {

    let $authors := mpese-text:authors($model('text'))
    return
        (mpese-text:author-label($authors), '&apos;', mpese-text:title($model('text')), '&apos;')
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
    let $images := $model('text')//tei:pb[@facs]/@facs/string()
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