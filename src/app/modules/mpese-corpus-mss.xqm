xquery version "3.1";

module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';

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
            if (fn:count($results) eq 0) then
                <p>No details</p>
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
            if (count($hands) eq 0) then <p>No details</p> else
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
            if (count($results) eq 0) then
                <p>No details</p>
            else
                for $item in $results
                    return <p>{fn:normalize-space($item/string())}</p>
        }</div>
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

let $results := for $item in doc('/db/mpese/tei/corpus/mss/BLAddMS35331.xml')//tei:body/tei:msDesc/tei:msContents/tei:msItem
                order by $item/@n
                return if (not(functx:has-empty-content($item))) then $item else ()

return
    <div id="mss-contents">{
        for $item in $results
            let $locus := <div class="mss-item-locus">{$item/tei:locus/string()}</div>
            let $title := if ($item/tei:title) then <div class="mss-item-title"><strong>Title:</strong>{text {' '}, $item/tei:title/string()}</div> else ()
            let $authors := for $author in $item/tei:author
                                return if (not(functx:has-empty-content($author))) then $author else ()
            let $author_list := if (count($authors) eq 0) then ()
                                else <div class="mss-item-author-list">{
                                    if (count($authors) eq 1) then
                                        (<strong>Author:</strong> , text {' '},local:person($authors[1]))
                                    else
                                        (<strong>Authors:</strong> , text {' '},
                                        for $author at $pos in $authors
                                            return
                                                if ($pos eq count($authors)) then
                                                    (' and ',  local:person($author))
                                        else
                                            (local:person($author),', ')
                                         )
                                }</div>
            let $resps := for $resp in $item/tei:respStmt
                          return if (not(functx:has-empty-content($resp))) then $resp else ()
            let $resp_list := if (count($resps) eq 0) then ()
                                else <div class="mss-resp-list"><strong>Responsibility:</strong>  {
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
                                        )}</div>
            return
                <div class="mss-item">{
                    ($locus, $title, $author_list, $resp_list)
                }</div>
    }</div>
};