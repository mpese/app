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

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

(: ---------- HELPER FUNCTIONS ----------- :)

declare function dashboard-mss:url($doc) {
    let $name := fn:substring-before($doc, '.xml')
    return
        fn:concat('../', $name, '/index.html')
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

declare %templates:wrap function dashboard-mss:details($node as node (), $model as map (*)) {
    let $mss_doc := doc($model('mss'))
    return
        for $item in $mss_doc/tei:TEI/tei:text/tei:body/tei:msDesc/tei:msContents/tei:msItem
        order by $item/@n
        return
            <div class="mss-entry">
                <p>{$item/tei:locus/text()}</p>
                <p>{$item/tei:title/text()} / {$item/tei:author/text()}</p>
            </div>
};
