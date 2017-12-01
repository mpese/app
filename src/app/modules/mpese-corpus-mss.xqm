xquery version "3.1";

module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';
import module namespace utils = 'http://mpese.rit.bris.ac.uk/utils/' at 'utils.xql';

(: get the list of mss documents :)
declare function mpese-mss:all-docs() {
    xmldb:get-child-resources($config:mpese-tei-corpus-mss)
};

(: get a single doc of mss documents :)
declare function mpese-mss:doc($doc) {
    fn:doc(concat($config:mpese-tei-corpus-mss, '/', $doc))
};

(: get the mss identifier - holds details of repository and mss shelf mark :)
declare function mpese-mss:identifier($mss_doc) {
    $mss_doc/tei:TEI/tei:text/tei:body/tei:msDesc/tei:msIdentifier
};

(: get the mss name :)
declare function mpese-mss:name($mss_doc) {
    $mss_doc//tei:body/tei:msDesc/tei:msIdentifier/tei:msName/text()
};

(: mss title - use the repo, collection, idno :)
declare function mpese-mss:title($mss_doc) {
    let $ident := mpese-mss:identifier($mss_doc)
    return
        concat($ident/tei:repository, ': ', $ident/tei:collection, ', ', $ident/tei:idno)
};



(: ---------- Functions to help render content  ----------- :)

(:~
 : Give details on the foliation used in the manuscript or a "No details" message.
 :
 : @param $foliation_list     list of <foliation/> elements.
 : @return the foliation details or a 'no details' message.
 :)
declare function mpese-mss:foliation-list($foliation_list as element()*) as element() {

    let $results := for $item in $foliation_list
        return if (not(functx:has-empty-content($item))) then $item else ()

    return
        <div id="foliation-details">{
            if (fn:count($results) eq 0 or fn:string-length($results[1]/string()) eq 0) then
                <p>No foliation details</p>
            else
                for $fol in $results return <p>{$fol/string()}</p>
        }</div>
};

(:~
 : Create a label for the MSS that a text comes from.
 :
 : @param $mss  the <msIdentifier/> element from the MSS.
 : @return a string representing the MSS details
 :)
declare function mpese-mss:ident-label($msIdentifier as element()?) as xs:string {
    if (count($msIdentifier/*) > 0) then
        $msIdentifier/tei:repository || ', ' || $msIdentifier/tei:collection || ', ' || $msIdentifier/tei:idno
    else
        "No manuscript details."
};


(: ---------- TEMPLATE FUNCTIONS ----------- :)

(:~
 : Adds the mss document to the model, so that it can be used by subsequent calls
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $mss      filename of the TEI/XML document
 : @return a map with the TEI/XML of the mss
 :)
declare function mpese-mss:mss($node as node (), $model as map (*), $mss as xs:string) {

    let $doc := $config:mpese-tei-corpus-mss || '/' || $mss
    return
        map { "mss" := $doc}
};

declare function mpese-mss:mss-ident($node as node (), $model as map (*)) {

    let $msIdentifier := doc($model('mss'))//tei:body/tei:msDesc/tei:msIdentifier
    return
        <h2>{mpese-mss:ident-label($msIdentifier)}</h2>
};

(:~
 : Give details on the foliation used in the manuscript.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $mss      filename of the TEI/XML document
 : @return the foliation details
 :)
declare function mpese-mss:foliation($node as node (), $model as map (*)) {

    let $foliation_results := doc($model('mss'))//tei:supportDesc/tei:foliation

    return  mpese-mss:foliation-list($foliation_results)
};

(:~
 : Give details on the different handwriting that appears in the manuscript.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $mss      filename of the TEI/XML document
 : @return details on the different handwriting that appears in the manuscript.
 :)
declare function mpese-mss:hand-notes($node as node (), $model as map (*)) {

    let $hands := for $x in doc($model('mss'))//tei:handDesc/tei:handNote order by $x/@n
                    return if (not (functx:has-empty-content($x))) then $x else ()

    return
        <div id="mss-hands">{
            if (count($hands) eq 0 or fn:string-length(fn:normalize-space($hands[1]/string())) eq 0) then <p>No details of hands</p> else
            <ul>{
                for $hand in $hands
                    return <li>{fn:normalize-space($hand/string())}</li>
            }</ul>
        }</div>
};

(:~
 : Give details on the history of the manuscript.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $mss      filename of the TEI/XML document
 : @return details on the the history of the manuscript.
 :)
declare function mpese-mss:history($node as node (), $model as map (*)) {

    let $results := for $item in doc($model('mss'))//tei:body/tei:msDesc/tei:history/*
                    return if (not(functx:has-empty-content($item))) then $item else ()

    return
        <div id="mss-history">{
            if (count($results) eq 0 or fn:string-length(fn:normalize-space($results[1]/string())) eq 0) then
                <p>No details</p>
            else
                for $item in $results
                    return <p>{fn:normalize-space($item/string())}</p>
        }</div>
};

declare function local:witness-label($name as xs:string) {

    let $doc := doc(concat($config:mpese-tei-corpus-texts, '/', $name, '.xml'))
    let $incl := $doc//tei:sourceDesc/tei:msDesc/xi:include
    let $target := $incl/@href/string()
    let $pointer := $incl/@xpointer/string()
    let $seq := fn:tokenize($target, '/')
    let $file := $seq[fn:last()]
    let $mss := doc(concat($config:mpese-tei-corpus-mss, '/', $file))
    let $desc := $mss//tei:msIdentifier[@xml:id=$pointer]
    return
        concat($desc//tei:repository, ', ', $desc//tei:collection, ', ', $desc//tei:idno)
};

declare function local:person($author) {
    if ($author/tei:persName and $author/tei:persName/@corresp) then
        let $link := $author/tei:persName/@corresp/string()
        let $id := fn:substring-after($link, '#')
            return
                if ($id) then
                    <span class='mss-item-person'><a href="../p/{$id}.html">{fn:normalize-space($author/string())}</a></span>
                else
                    <span class='mss-item-person'>{fn:normalize-space($author/string())}</span>
    else
        <span class='mss-item-person'>{fn:normalize-space($author/string())}</span>
};

declare function mpese-mss:contents($node as node (), $model as map (*)) {

let $results := for $item in doc($model('mss'))//tei:body/tei:msDesc/tei:msContents/tei:msItem
                order by $item/@n
                return if (not(functx:has-empty-content($item))) then $item else ()

return
    <div id="mss-contents">{
        for $item in $results

            (: item locus :)
            let $locus := <p class="mss-item-locus">{$item/tei:locus/string()}</p>

            (: item title :)
            let $title := if ($item/tei:title) then <span>{(text {"'"}, $item/tei:title/string(), text {"'"})}</span> else ()

            (: authors :)
            let $authors := for $author in $item/tei:author
                                return if (not(functx:has-empty-content($author))) then $author else ()
            let $author_list := if (count($authors) eq 0) then ()
                                else
                                    if (count($authors) eq 1) then
                                        (text {' by '},local:person($authors[1]))
                                    else
                                        (text {' by '},
                                        for $author at $pos in $authors
                                            return
                                                if ($pos eq count($authors)) then
                                                    (' and ',  local:person($author))
                                        else
                                            (local:person($author),', ')
                                         )


            (: scribes and others responsible for the item :)
            let $resps := for $resp in $item/tei:respStmt
                          return if (not(functx:has-empty-content($resp))) then $resp else ()
            let $resp_list := if (count($resps) eq 0) then ()
                                else <span class="mss-resp-list"><em>Responsibility:</em>  {
                                    if (count($resps) eq 1) then
                                        (text { ' ' }, local:person($resps[1]/tei:name), ' (' || $resps[1]/tei:resp/string() || ')')
                                    else
                                        (text { ' ' },
                                        for $resp at $pos in $resps
                                            return
                                                if ($pos eq count($resps)) then
                                                    (' and ',  local:person($resp/tei:name), ' (' || $resp/tei:resp/string() || ')')
                                        else
                                            (local:person($resp/tei:name), ' (' || $resp/tei:resp/string() || ')',', ')
                                        )}</span>

            (: links to transcripts :)
            let $links := $item/tei:link[@type = 'witness' or @type = 't_witness']
            let $links_list := if (count($links) eq 0) then ()
                                    else <ul class="mss-link-list">{
                                        for $link in $links
                                            let $name := utils:name-from-uri($link/@target/string())
                                            return
                                                if ($name and $link/@type/string() eq 't_witness') then
                                                    <li><a href="../t/{$name}.html">Witness from this MS</a></li>
                                                else if ($name and $link/@type/string() eq 'witness') then
                                                    let $label := local:witness-label($name)
                                                    return
                                                        <li><a href="../t/{$name}.html">Witness from {$label}</a></li>
                                                else
                                                    ()
                                    }</ul>


            let $history := if (fn:string-length(fn:normalize-space($item/tei:msDesc/tei:history/string())) eq 0) then ()
                            else <span><em>History:</em> {text { ' ' }, fn:normalize-space($item/tei:msDesc/tei:history/string())}</span>

            let $notes := if ($resp_list or $history) then <p>{$history, text {' '}, $resp_list}</p> else ()

            return
                <div class="mss-item">{
                    ($locus, <p>{$title, $author_list}</p>, $notes, $links_list)
                }</div>
    }</div>
};