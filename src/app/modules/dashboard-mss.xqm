module namespace dashboard-mss = "http://mpese.rit.bris.ac.uk/dashboard/mss/";

(:
 : A Module with functions for rendering the details of a manuscript within the researcher's
 : dashboard area. The name of the file is part of the URL, so BLAddMS11049.xml
 : appears in the dashboard URL as dashboard/mss/BLAddMS11049/index.html.
 : The application controller extracts the name from the URL, appends '.xml' and forwards
 : it to mss_item.html
 :)

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";
import module namespace mpese-mss = "http://mpese.rit.bris.ac.uk/corpus/mss/" at 'mpese-corpus-mss.xqm';
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

(: ---------- HELPER FUNCTIONS ----------- :)

declare function dashboard-mss:url($doc) {
    let $name := fn:substring-before($doc, '.xml')
    return
        fn:concat('./', $name, '.html')
};

declare function dashboard-mss:witness-label($name as xs:string) {

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

(: get a person and link to their details :)
declare function dashboard-mss:person($person) {
    let $corresp := $person//@corresp/string()
    return
        if (fn:string-length($corresp) > 0) then
            let $id := fn:tokenize($corresp, '#')[2]
            return <a href="../people/{$id}.html">{functx:trim($person/string())}</a>
        else
            functx:trim($person/string())
};


(: ---------- TEMPLATE FUNCTIONS ----------- :)

(: display a table of manuscripts :)
declare function dashboard-mss:all($node as node (), $model as map (*)) {
    let $docs := mpese-mss:all-docs()
    return
        <table class='table table-respossive'>
            <thead>
                <tr>
                    <th>Repository</th>
                    <th>Collection</th>
                    <th>ID No.</th>
                    <th>Last modified</th>
                </tr>
            </thead>
            <tbody>{
        for $doc in $docs
        order by $doc ascending
            let $mss := mpese-mss:identifier(mpese-mss:doc($doc))
            return
            <tr>
                <td><a href='{dashboard-mss:url($doc)}'>{$mss/tei:repository}</a></td>
                <td>{$mss/tei:collection}</td>
                <td>{$mss/tei:idno}</td>
                <td>{fn:format-dateTime(xmldb:last-modified($config:mpese-tei-corpus-mss, $doc), $config:date-time-fmt)}</td>
            </tr>
            }</tbody>
        </table>
};

(: adds the full URI of the mss to the map so that it can be used by the following functions -
 : the $mss variable is passed in via the controller; it generates it from the requested
 : URL, which includes the name of the file :)
declare function dashboard-mss:find-mss($node as node (), $model as map (*), $mss as xs:string) {
    map { "mss" := concat($config:mpese-tei-corpus-mss, '/', $mss) }
};

(: title of the mss :)
declare %templates:wrap function dashboard-mss:title($node as node (), $model as map (*)) {
    mpese-mss:title(doc($model('mss')))
};

(: name of the mss :)
declare %templates:wrap function dashboard-mss:name($node as node (), $model as map (*)) {
    mpese-mss:name(doc($model('mss')))
};

declare %templates:wrap function dashboard-mss:details($node as node (), $model as map (*)) {
    let $mss_doc := doc($model('mss'))
    return
        for $item in $mss_doc/tei:TEI/tei:text/tei:body/tei:msDesc/tei:msContents/tei:msItem
        order by number($item/@n)
        return
            <div class="mss-entry">
                <p><strong>{$item/tei:locus/text()}</strong></p>
                <p>
                {
                let $auth_count := fn:count($item/tei:author)
                return
                    if ($auth_count > 0) then
                        <span class='mss-entry-author'>{
                            if ($auth_count > 1) then
                                for $author at $pos in $item/tei:author
                                    return
                                        if ($pos eq $auth_count) then
                                            (' and ',  dashboard-mss:person($author))
                                        else
                                            (dashboard-mss:person($author),', ')
                            else
                                dashboard-mss:person($item/tei:author)},</span>

                    else
                        ""
                }
                '{$item/tei:title/text()}'</p>
                {
                    let $resp_count := fn:count($item/tei:respStmt)
                    return
                        if ($resp_count > 0) then
                            <p>{
                                if ($resp_count > 1) then
                                    for $resp at $pos in $item/tei:respStmt
                                        return
                                            if ($pos eq $resp_count) then
                                                concat(' and ', dashboard-mss:person($resp/tei:name), ' (', $resp/tei:role/string(), ')')
                                            else
                                                concat(dashboard-mss:person($resp/tei:name), ' (', $resp/tei:resp/string(), ')', ', ')
                                else
                                    (dashboard-mss:person($item/tei:respStmt/tei:name), concat(' (', $item/tei:respStmt/tei:resp/string(), ')'))
                        }</p>
                        else
                            ""
                }
                {
                    let $link_count := fn:count($item/tei:link)
                    return
                        if ($link_count > 0) then
                            <ul class='mss-entry-witnesses unstyled'>{
                                for $link in $item/tei:link
                                return
                                    <li class='mss-entry-witness unstyled'>{
                                        let $target := $link/@target/string()
                                        let $type := $link/@type/string()
                                        let $name := utils:name-from-uri($target)
                                        let $url := concat('../text/', $name, '.html')
                                        return
                                            if ($type eq 't_witness') then
                                                <a href="{$url}">Transcript of the witness from this MS</a>
                                            else
                                                let $label := dashboard-mss:witness-label($name)
                                                    return
                                                <a href="{$url}">Transcript of a witness from {$label}</a>
                                    }</li>
                            }</ul>
                        else
                            ""
                }
            </div>
};
