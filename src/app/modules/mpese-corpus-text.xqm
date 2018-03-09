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
declare function mpese-text:title-label($doc) as xs:string {

    let $tmp_title := $doc//tei:fileDesc/tei:titleStmt/tei:title/string()
    let $tmp_date := $doc//tei:profileDesc/tei:creation/tei:date[1]/string()
    let $title := ( if (fn:string-length($tmp_title) > 0) then $tmp_title else fn:string('Untitled') )
    let $date  := ( if (fn:string-length($tmp_date) > 0) then $tmp_date else fn:string('No date') )
    return
        concat($title, ' (', $date, ')')
};

(:~
 :   Provide the title of the text (with date) or 'untitled'.
 :
 :  @param $text      the TEI/XML document.
 :  @return the title of the text of 'untitled'
 :)
declare function mpese-text:title($text as xs:string) as xs:string {
    mpese-text:title-label(doc($text)//tei:TEI)
};

(:~
 :  The list of authors associated with a text.
 :  Note: some might be signatories and not actually authors.
 :
 :  @param $doc      the TEI/XML document.
 :  @return a list of author elements.
 :)
declare function mpese-text:authors($text as xs:string, $has_roles as xs:boolean) as element()* {
        if ($has_roles) then
            doc($text)//tei:fileDesc/tei:titleStmt/tei:author
        else
            doc($text)//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
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
declare function mpese-text:mss-details($doc as element()) as element()? {

    (: get the include :)
    let $include := $doc//tei:sourceDesc/tei:msDesc/xi:include

    return
        mpese-text:mss-details-include($include)
};

(:~
 : Get the text types associated with a text.
 :
 : @param $text      the TEI/XML document.
 : @return the text types for a text
 :)
declare function mpese-text:keywords-text-type($text as xs:string) as element()* {
    doc($text)//tei:profileDesc/tei:textClass/tei:keywords[@n='text-type']/tei:term
};

(:~
 : Get the keywords associated with a text.
 :
 : @param $text      the TEI/XML document.
 : @return the keywords for a text
 :)
declare function mpese-text:keywords-topic($text as xs:string) as element()* {
    doc($text)//tei:profileDesc/tei:textClass/tei:keywords[@n='topic-keyword']/tei:term
};

(:~
 : Display the text (delegate to an xsl file)
 :
 :  @param $text      the TEI/XML document.
 :  @return the transcript marked up as HTML
 :)
declare function mpese-text:text-body($text as xs:string) as node()* {
    let $lm := if (count(doc($text)//tei:add[@place='LM']) > 0) then 'mpese-text-lm' else ()
    let $rm := if (count(doc($text)//tei:add[@place='LM']) > 0) then 'mpese-text-rm' else ()
    let $css := fn:string-join(($lm,$rm), " ")
    let $xsl := doc('corpus-text-html.xsl')
    let $transcript := doc($text)
    let $proof_read :=  if (not(boolean($transcript//tei:revisionDesc/tei:listChange/tei:change[@status = 'proofread']))) then
                            <div class="alert alert-warning" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span class="sr-only">Warning:</span>
                                This transcript is marked as a draft and is awaiting proof reading
                            </div>
                            else
                            ()
    return
        <div id="mpese-text-body" class="{$css}">{$proof_read}{transform:transform($transcript, $xsl, ())}</div>
};


(:~
 : Get the <msIdentifier/> for the witnesses by following xincludes under the
 : <listBibl xml:id="witness"/> element
 :
 :  @param $text      the TEI/XML document.
 :  @return the XML for the witnesses
 :)
declare function mpese-text:witnesses-includes($text as xs:string) as element()*  {

    (: find the include nodes :)
    let $witnesses := doc($text)//tei:listBibl[@xml:id='mss_witness']/tei:bibl/xi:include

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
 :  @param $text      the TEI/XML document.
 :  @return the creation date of the document
 :)
declare function mpese-text:creation-date($text as xs:string) as element()* {
    doc($text)//tei:profileDesc/tei:creation/tei:date
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
 : @param $text      the TEI/XML document.
 : @return the languages used in the document
 :)
declare function mpese-text:languages($text as xs:string) as element()* {
    doc($text)//tei:profileDesc/tei:langUsage/tei:language
};

(:~
 : Create a label for the folio numbers of a text.
 :)
declare function mpese-text:folios($doc as node()) as xs:string {
    let $folios := for $folio in $doc//tei:text/tei:body/tei:pb/@n/string()
                   order by $folio ascending return $folio
    return
        if (count($folios) eq 0) then ''
        else if (count($folios) > 1) then ', ff. ' || $folios[1] || "-" || $folios[last()]
        else ', f. ' || $folios[1]

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
            return <span class="mpese-person"><a href="../p/{$id}.html">{fn:normalize-space(fn:string-join($person/descendant-or-self::*[not(*)], ' '))}</a></span>
        else
            <span class="mpese-person">{fn:normalize-space(fn:string-join($person/descendant-or-self::*[not(*)], ' '))}</span>
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
        if ($auth_count eq 0) then
            ()
        else if ($auth_count eq 1) then
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

(:~
 : Show the text details with a link to the text.
 :
 : @param $mss          the manuscript details.
 : @param $show_link    show a URL to the manuscript details?
 : @return details with a link to the text
 :)
declare function mpese-text:mss-with-link($mss as element()?, $doc as node()?) as element()? {
    if ($mss) then
        let $mss_doc := base-uri($mss)
        let $name := utils:name-from-uri($mss_doc)
        return
            <a href="../m/{$name}.html">{mpese-mss:ident-label($mss)}{mpese-text:folios($doc)}</a>
    else
        ()
};

(:~
 : Author section of a printed bibliographical item
 :
 : @param $bibl         a bibliographical element
 : @param $show_link    show a URL to the person?
 : @return the author section of a printed bibliographical item
 :)
declare function mpese-text:bibl-author($bibl as element()) as element()? {
    if ($bibl/tei:author and not(functx:has-empty-content($bibl/tei:author))) then
        mpese-text:author-label-r((), $bibl/tei:author, true())
    else
        ()
};

(:~
 : Title section of a printed bibliographical item
 :
 : @param $bibl         a bibliographical element
 : @return the title section of a printed bibliographical item
 :)
declare function mpese-text:bibl-title($bibl as element()) as element()? {
    if ($bibl/tei:title and not(functx:has-empty-content($bibl/tei:title))) then
        <em>{$bibl/tei:title/string()}</em>
    else
        ()
};

(:~
 : Publication section of a printed bibliographical item
 :
 : @param $bibl         a bibliographical element
 : @return the publication section
 :)
declare function mpese-text:bibl-pub($bibl as element()) as xs:string {
    let $pub := string-join(($bibl/tei:edition, $bibl/tei:pubPlace, $bibl/tei:date), ', ')
    return
        if ($pub) then
            ' (' || $pub || ')'
        else
            ""
};

(:~
 : Identification section of a printed bibliographical item
 :
 : @param $bibl         a bibliographical element
 : @return the identification section
 :)
declare function mpese-text:bibl-idno($bibl as element()) as xs:string {
    let $id := string-join(($bibl/tei:idno/@type/string(), $bibl/tei:idno), ' ')
    return
        if ($id) then
            ' [' || $id || ']'
        else
            ""
};

declare function mpese-text:biblio-vol($bibl as element()) as xs:string {
    if (boolean($bibl/tei:biblScope[@unit="volume"])) then
        let $vols := $bibl/tei:biblScope[@unit="volume"]
            return
                if (count($vols) > 1) then
                    ", vols. " || fn:string-join($bibl/tei:biblScope[@unit="volume"], ", ")
                else
                    ", vol. " || $bibl/tei:biblScope[@unit="volume"]/string()
    else
        ""
};

(:~
 : Pages and sigs ... are the 'to' and 'from' attribute vales the same?
 :
 : @param $scope         a <biblScope/> element
 : @return true() if the same otherwise false()
 :)
declare function mpese-text:sameBiblScopeVal($scope) as xs:boolean {
    $scope/@from/string() eq $scope/@to/string()
};

(:~
 : Do we need a page or sig prefix.
 :
 : @param $type         page or sig?
 : @param $plural       more than one?
 : @return 'p.', 'pp.', 'sig.' or 'sigs.'
 :)
declare function mpese-text:bibloScopePrefix($type as xs:string, $plural as xs:boolean) as xs:string {
    if ($type eq 'page') then
        if ($plural) then ', pp. ' else ', p. '
    else if ($type eq 'sigs') then
        if ($plural) then ', sigs. ' else ', sig. '
    else
        ""
};

(:~
 : Work out the prefix needed (eg. pp.) for the bibliography.
 :
 : @scope_list          a list of <tei:biblScope/> elements
 : @type                'page' or 'sigs'
 :)
declare function mpese-text:biblScopePrefix($scope_list, $type) {
    if (count($scope_list) eq 0) then
        ""
    else if (count($scope_list) > 1) then
        mpese-text:bibloScopePrefix($type, true())
    else
        if ($scope_list[1]/@from and $scope_list[1]/@to) then
            if (not(mpese-text:sameBiblScopeVal($scope_list[1]))) then
               mpese-text:bibloScopePrefix($type, true())
        else
            mpese-text:bibloScopePrefix($type, true())
    else
       mpese-text:bibloScopePrefix($type, false())
};

declare function mpese-text:biblScopePrefix($bibl as element()) {

    if (boolean($bibl/tei:biblScope[@unit = 'page'])) then
        (mpese-text:biblScopePrefix($bibl/tei:biblScope[@unit = 'page'], 'page'),
        mpese-text:outputScope($bibl/tei:biblScope[@unit = 'page']))
    else if (boolean($bibl/tei:biblScope[@unit = 'sigs'])) then
        (mpese-text:biblScopePrefix($bibl/tei:biblScope[@unit = 'sigs'], 'sigs'),
        mpese-text:outputScope($bibl/tei:biblScope[@unit = 'sigs']))
    else
        ""

};

(:~
 : Create a comma separated list of pages, sigs etc from the <tei:biblScope/> elements.
 :)
declare function mpese-text:outputScope($scope_list) {
    let $ranges :=
            for $range in $scope_list
                let $f := string-join(($range/@from/string(),$range/@to/string()), '–')
                return
                    if ($f) then
                        $f
                    else
                        $range/string()
    return
        string-join($ranges, ', ')
};

declare function mpese-text:bibliography($biblio_list) {

    if (count($biblio_list) eq 0 or functx:has-empty-content($biblio_list[1])) then
        <p>No bibliography</p>
    else
        <ul>{
            for $item in $biblio_list
                return
                    <li>{
                        let $authors := mpese-text:bibl-author($item)
                        let $title := mpese-text:bibl-title($item)
                        let $pub := mpese-text:bibl-pub($item)
                        let $id := mpese-text:bibl-idno($item)
                        let $vols := mpese-text:biblio-vol($item)
                        let $seq := ($authors, $title)
                        let $f := for $item at $pos in $seq
                            return
                                if ($item and $seq[$pos + 1]) then
                                    ($item, text { ', '})
                                else
                                    $item
                        let $scope := mpese-text:biblScopePrefix($item)
                        return
                            ($f, fn:string-join(($pub, $id, $vols, $scope), ''))
                    }</li>
        }</ul>

};

(:~
 : Display the creation date.
 :
 : @param $date_list     the list of dates
 : @return the creation date or a 'No details' message
 :)
declare function mpese-text:creation-date-label($date_list as element()*) {

    let $dates :=
        for $date in $date_list
        return
            let $val := if ($date/string()) then
                $date/string()
            else if ($date/@when/string()) then
                    $date/@when/string()
                else
                    ""
            return
                if ($date/@type/string()) then
                    $val || ' (' || $date/@type/string() || ')'
                else
                    $val
    let $val := string-join($dates, ', ')
    return
        if ($val) then
            $val
        else
            "No details"
};


(:~
 : Display a list of text topic keywords.
 :
 : @param $text-types     XML list
 : @return the list of text topic keywords as HTML
 :)
declare function mpese-text:keywords-label($keywords) {
    if (count($keywords) eq 0) then
        <p>No text types.</p>
    else
        <ul class="list-inline">{
            for $type in $keywords
                return
                    if (not(functx:has-empty-content($type))) then
                        <li>{$type/string()}</li>
                    else
                        ()
        }</ul>
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

    let $text := $config:mpese-tei-corpus-texts || '/' || $text
    let $mss := mpese-text:mss-details(doc($text)//tei:TEI/tei:teiHeader/tei:fileDesc)
    return
        map { "text" := $text, "mss" := $mss}
};

(:~
 : Provides a link back to the search if the cookies have the value.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $text     filename of the TEI/XML document
 : @return a link to the original search
 :)
declare function mpese-text:search-nav($node as node (), $model as map (*)) {
    utils:search-nav('../../')
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
    let $authors := mpese-text:authors($model('text'), false())
    return
        <h2 class="mpese-item-title">{(mpese-text:author-label($authors), text{' &apos;'}, mpese-text:title($model('text')), text{'&apos;'})}</h2>
};

(:~
 : Display basic mss details with link to MSS.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the details of the manuscript
 :)
declare function mpese-text:mss($node as node (), $model as map (*)) {
    <p>{mpese-text:mss-with-link($model('mss'), doc($model('text')))}</p>
};

(: ----- Main text tab -----:)

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
 : Display the tags needed for the OpenSeaDragon viewer.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return HTML for the viewer or a 'No image' message
 :)
declare function mpese-text:image($node as node (), $model as map (*)) {
    let $has_images := exists(doc($model('text'))//tei:facsimile)
    return
        if ($has_images) then
            <div id='facsimile' data-doc-type="text" data-doc-id="{utils:name-from-uri($model('text'))}">
                <div id="openseadragon"></div>

            </div>
        else
            <div class="well well-lg"><p class="text-center font-weight-bold">No image</p></div>
};

(: ----- Text details tab -----:)

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
            <p>{mpese-text:mss-with-link($model('mss'), doc($model('text'))),
                if (not(functx:has-empty-content($model('mss')//tei:msName))) then
                    (text{', '},($model('mss')//tei:msName/string()))
                else
                    ""
            }</p>
        else
            <p>No manuscript details</p>
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

(:~
 : Display the creation date.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the creation date or a 'No details' message
 :)
declare function mpese-text:creation-date($node as node (), $model as map (*)) {

    let $date_list := mpese-text:creation-date($model('text'))
    return
        mpese-text:creation-date-label($date_list)
};

(:~
 : Display a list of authors.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of authors
 :)
declare function mpese-text:author-list($node as node (), $model as map (*)) {
    let $authors := mpese-text:authors($model('text'), true())

    return
        (: Check if we have a list or the first item of the list is empty (usually a comment saying
           content nees to be added :)
        if (count($authors) eq 0 or functx:has-empty-content($authors[1])) then
            <p>No authors.</p>
        else
            <ul>{
                for $author in $authors
                    let $role := if ($author/@role/string()) then ' (' || $author/@role/string() || ')' else ""
                    return
                        <li>{mpese-text:person($author, true())}{$role}</li>
            }</ul>
};

(:~
 : Display the list of witnesses
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of witnesses or a "no witnesses" message
 :)
declare function mpese-text:witnesses($node as node (), $model as map (*)) {

    let $witnesses := doc($model('text'))//tei:listBibl[@xml:id="mss_witness_generated"]/tei:bibl

    return
    if (count($witnesses) eq 0) then
        <p>No witnesses</p>
    else
        <ul>{
            for $witness in $witnesses
            order by $witness//tei:ref[@type='ms']/string()
            return <li>{
                let $transcript := if ($witness/tei:ref[@type='text']) then
                    let $link := './' || substring-before($witness/tei:ref[@type='text']/@target/string(), '.xml') || '.html'
                    return (<a href="{$link}">Transcript</a>, text{" of "})
                    else
                        ()
                let $ms := if ($witness//tei:ref[@type='ms']) then
                    let $target := $witness//tei:ref[@type='ms']/@target/string()
                    let $tmp := substring-after($target, 'mss/')
                    let $link := '../m/' || substring-before($tmp, '.xml') || '.html'
                    return (<a href="{$link}">{$witness//tei:ref[@type='ms']/string()}</a>)
                    else
                        ()
                return
                    ($transcript, $ms)
            }</li>

        }</ul>

};

(:~
 : Display the contemporary printed witnesses.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of contemporary witnesses.
:)
declare function mpese-text:contemporary-witnesses($node as node (), $model as map (*)) {

    let $witnesses := doc($model('text'))//tei:sourceDesc/tei:listBibl[@xml:id = 'C17_print_witness']/tei:bibl

    return
        mpese-text:bibliography($witnesses)
};

(:~
 : Display the modern printed witnesses.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return the list of modern print witnesses.
:)
declare function mpese-text:modern-witnesses($node as node (), $model as map (*)) {

    let $witnesses := doc($model('text'))//tei:sourceDesc/tei:listBibl[@xml:id = 'modern_print_witness']/tei:bibl

    return
        mpese-text:bibliography($witnesses)
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
        mpese-text:keywords-label($text-types)
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
        mpese-text:keywords-label($text-types)
};