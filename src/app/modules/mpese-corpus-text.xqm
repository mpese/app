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
import module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/' at 'mpese-corpus-mss.xqm';
import module namespace utils = 'http://mpese.rit.bris.ac.uk/utils/' at 'utils.xql';


(: --------- Functions that return bits of XML ---------- :)

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
 : @param $include     the Xinclude element with details of the MS.
 : @return the <msIdentifier/> of a MSS a text is derived, via an xinclude in the text.
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
 : @param $doc      the TEI/XML document.
 : @return the <msIdentifier/> of the MSS the text is derived.
 :)
declare function mpese-text:mss-details($doc as element()?) as element()? {

    (: get the include :)
    let $include := $doc//tei:sourceDesc/tei:msDesc/xi:include

    return
        mpese-text:mss-details-include($include)
};

(:~
 : Get the text types associated with a text.
 :
 : @param $doc      the TEI/XML document.
 : @return the text types for a text
 :)
declare function mpese-text:keywords-text-type($doc as element()) as element()* {
    $doc//tei:profileDesc/tei:textClass/tei:keywords[@n='text-type']/tei:term
};

(:~
 : Get the keywords associated with a text.
 :
 : @param $doc      the TEI/XML document.
 : @return the keywords for a text
 :)
declare function mpese-text:keywords-topic($doc as element()) as element()* {
    $doc//tei:profileDesc/tei:textClass/tei:keywords[@n='topic-keyword']/tei:term
};

(:~
 : Display the text (delegate to an xsl file)
 :
 :  @param $doc      the TEI/XML document.
 :  @return the transcript marked up as HTML
 :)
declare function mpese-text:text-body($doc as node()) as node()* {
    let $xsl := doc('corpus-text-html.xsl')
    return
        transform:transform($doc, $xsl, ())
};


(:~
 : Get the <msIdentifier/> for the witnesses by following xincludes under the
 : <listBibl xml:id="witness"/> element
 :
 :  @param $doc      the TEI/XML document.
 :  @return the XML for the witnesses
 :)
declare function mpese-text:witnesses-includes($doc as node()) as element()*  {

    (: find the include nodes :)
    let $witnesses := $doc//tei:listBibl[@xml:id='mss_witness']/tei:bibl/xi:include

    (: follow each include to get the manuscript details :)
    for $include in $witnesses

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

(:~
 : Get the creation date of a document
 :
 :  @param $doc      the TEI/XML document.
 :  @return the creation date of the document
 :)
declare function mpese-text:creation-date($doc as node()) as xs:string? {
    $doc//tei:profileDesc/tei:creation/tei:date/string()
};

(:~
 : Get the place the document was created.
 :
 : @param $doc      the TEI/XML document.
 : @return the creation place of the document
 :)
declare function mpese-text:creation-place($doc as node()) as element()* {
    $doc//tei:profileDesc/tei:creation/tei:placeName
};

(:~
 : Languages used in the document.
 :
 : @param $doc      the TEI/XML document.
 : @return the languages used in the document
 :)
declare function mpese-text:languages($doc as node()) as element()* {
    $doc//tei:profileDesc/tei:langUsage/tei:language
};

(: ---------- Functions to help render content  ----------- :)

(:~
 : Get a person and link to their details (if required)
 :
 : @param $person       person details
 : @param $show_link    show a link?
 : @return a span tag with the person's name and an optional link to theie details.
 :)
declare function mpese-text:person($person, $show_link as xs:boolean) {
    let $corresp := $person//@corresp/string()
    return
        if (fn:string-length($corresp) > 0 and $show_link eq true()) then
            let $id := fn:tokenize($corresp, '#')[2]
            return <span class="mpese-person"><a href="../people/{$id}/">{fn:normalize-space($person/string())}</a></span>
        else
            <span class="mpese-person">{fn:normalize-space($person/string())}</span>
};

(:~
 : Recursive function to create a formatted string of authors for a text.
 :
 : @param $label        the current label
 : @param $authors      the current sequence of authors.
 : @return a formatted label of authors.
 :)
declare function mpese-text:author-label-r($label as node()*, $authors as node()*, $show_link as xs:boolean) {

    let $auth_count := fn:count($authors)
    return
        if ($auth_count eq 1) then
            ($label, mpese-text:person($authors[1], $show_link))
        else if ($auth_count eq 2) then
            let $tmp_label := ($label, mpese-text:person($authors[1], $show_link) , text{', and '})
            let $tmp_authors := fn:subsequence($authors, 2)
            return
                mpese-text:author-label-r($tmp_label, $tmp_authors, $show_link)
        else
            let $tmp_label := ($label, mpese-text:person($authors[1], $show_link), text{', '})
            let $tmp_authors := fn:subsequence($authors, 2)
            return
                mpese-text:author-label-r($tmp_label, $tmp_authors, $show_link)
};


(:~
 : Entry point for the recursive function to create a formatted string of authors for a text.
 : Don't show links to the people details.
 :
 : @param $authors      the current sequence of authors.
 : @return a formatted label of authors.
 :)
declare function mpese-text:author-label($authors as element()*) as element() {
    <span class="mpese-author-list">{mpese-text:author-label-r((), $authors, false())}</span>
};

(:~
 : Entry point for the recursive function to create a formatted string of authors for a text.
 : Option to show links to the people details.
 :
 : @param $authors      the current sequence of authors.
 : @param $show_link    show a URL to the person details?
 : @return a formatted label of authors.
:)
declare function mpese-text:author-label($authors as element()*, $show_link as xs:boolean) as element() {
    <span class="mpese-author-list">{mpese-text:author-label-r((), $authors, $show_link)}</span>
};

declare function mpese-text:mss-with-link($mss as element()?) as element()? {
    if ($mss) then
        let $mss_doc := base-uri($mss)
        let $name := utils:name-from-uri($mss_doc)
        return
            <a href="../m/{$name}.html">{mpese-mss:ident-label($mss)}</a>
    else
        ()
};

(: ---------- TEMPLATE FUNCTIONS ----------- :)

(:~
 : Adds the text document and the basic details about the manuscript to the model,
 : so that it can be used by subsequent calls
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $text     filename of the TEI/XML document
 : @return a map with the TEI/XML of the text and an <msIdentifier/> fragment
 :)
declare function mpese-text:text($node as node (), $model as map (*), $text as xs:string) {

    let $doc := doc(concat($config:mpese-tei-corpus-texts, '/', $text))//tei:TEI
    let $mss := mpese-text:mss-details($doc)
    return
        map { "text" := $doc, "mss" := $mss}
};

(:~
 : Display the author and title of the text.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return a the authors and title.
 :)
declare function mpese-text:author-title($node as node (), $model as map (*)) {

    (: get the authors :)
    let $authors := mpese-text:authors($model('text'))
    return
        <h2>{(mpese-text:author-label($authors), text{' &apos;'}, mpese-text:title($model('text')), text{'&apos;'})}</h2>
};

(:~
 : Display basic mss details with link to MSS.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the details of the manuscript
 :)
declare function mpese-text:mss($node as node (), $model as map (*)) {
    <p>{mpese-text:mss-with-link($model('mss'))}</p>
};

(:~
 : Display the mss name
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the name of the manuscript
 :)
declare function mpese-text:mss-name($node as node (), $model as map (*)) {
    if (not(functx:has-empty-content($model('mss')//tei:msName))) then
        <p>{$model('mss')//tei:msName/string()}</p>
    else
        ""
};

(:~
 : Display basic mss details with link to MSS and the mss name
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the name of the manuscript
 :)
declare function mpese-text:mss-name-full($node as node (), $model as map (*)) {

    let $mss := $model('mss')
    return
        if ($mss) then
            <p>{mpese-text:mss-with-link($model('mss')),
                if (not(functx:has-empty-content($model('mss')//tei:msName))) then
                    (text{', '},($model('mss')//tei:msName/string()))
                else
                    ""
            }</p>
        else
            <p>No manuscript details</p>
};

(:~
 : Display the tags needed for the OpenSeaDragon viewer.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return HTML for the viewer or a 'No image' message
 :)
declare function mpese-text:image($node as node (), $model as map (*)) {
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

(:~
 : Display the transcript
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the transcript as HTML
 :)
declare function mpese-text:transcript($node as node (), $model as map (*)) {
    mpese-text:text-body($model('text'))
};

(:~
 : Display the list of witnesses
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of witnesses or a "no witnesses" message
 :)
declare function mpese-text:witnesses($node as node (), $model as map (*)) {
    let $witnesses := mpese-text:witnesses-includes($model('text'))
    return
        if (count($witnesses) eq 0) then
            <p>No witnesses</p>
        else
            <ul class="list-unstyled">{
                for $witness in $witnesses
                    return
                        <li>{mpese-text:mss-with-link($witness)}</li>
            }</ul>
};

(:~
 : Display a list of authors.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of authors
 :)
declare function mpese-text:author-list($node as node (), $model as map (*)) {
    let $authors := mpese-text:authors($model('text'))

    return
        if (count($authors) eq 0) then
            <p>No authors.</p>
        else
            <ul class="list-unstyled">{
                for $author in $authors
                    return
                        <li>{mpese-text:person($author, true())}</li>
            }</ul>
};

(:~
 : Display a list of text type keywords.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of text type keywords
 :)
declare function mpese-text:text-type($node as node (), $model as map (*)) {
    let $text-types := mpese-text:keywords-text-type($model('text'))

    return
        if (count($text-types) eq 0) then
            <p>No text types.</p>
        else
            <ul class="list-inline">{
                for $type in $text-types
                    return
                        if (not(functx:has-empty-content($type))) then
                            <li>{$type/string()}</li>
                        else
                            ()
            }</ul>
};

(:~
 : Display a list of text topic keywords.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of text topic keywords
 :)
declare function mpese-text:text-topic($node as node (), $model as map (*)) {
    let $text-types := mpese-text:keywords-topic($model('text'))

    return
        if (count($text-types) eq 0) then
            <p>No text types.</p>
        else
            <ul class="list-inline">{
                for $type in $text-types
                    return
                        if (not(functx:has-empty-content($type))) then
                            <li>{$type/string()}</li>
                        else
                            ()
            }</ul>
};

(:~
 : Display a list of text topic keywords.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of text topic keywords
 :)
declare function mpese-text:lang($node as node (), $model as map (*)) {

    let $lang := mpese-text:languages($model('text'))

    return
        if ($lang and not(empty(fn:string-join($lang)))) then
            "No details"
        else
            fn:string-join($lang, ', ')
};

declare function mpese-text:creation-date($node as node (), $model as map (*)) {

    let $creation := mpese-text:creation-date($model('text'))

    return

        if ($creation and not(empty(fn:string-join($creation)))) then
            mpese-text:creation-date($model('text'))
        else
            "No details"

};