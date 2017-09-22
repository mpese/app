module namespace dashboard-text = "http://mpese.rit.bris.ac.uk/dashboard/text/";

(:
 : A Module with functions for rendering the details of a text within the researcher's
 : dashboard area. The name of the file is part of the URL, so AbbotJamesNullity1613.xml
 : appears in the dashboard URL as dashboard/text/AbbotJamesNullity1613/index.html.
 : The application controller extracts the name from the URL, appends '.xml'  and forwards
 : it to text.html
 :)

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";
import module namespace mpese-text = "http://mpese.rit.bris.ac.uk/corpus/text/" at 'mpese-corpus-text.xqm';
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/";

(: ---------- HELPER FUNCTIONS ------------- :)

(: helper function for listing items - replaces duplicate values and ignore empty items :)
declare function dashboard-text:items-as-list($list) {
    <ul class='list-inline'>{
        for $item in fn:distinct-values($list)
        order by $item ascending
            return
                if(not(functx:all-whitespace($item))) then
                    <li>{$item}</li>
                else
                    ()
    }</ul>
};

(: Manuscript details for a text. This is the <msIdentifier/> and this usually comes from following an xinclude :)
declare function dashboard-text:mss-details($node as node()) {

    (: get the base URI of the mss :)
    let $mss_uri := fn:base-uri($node)

    (: work out the name  of the file, without an extension :)
    let $name := utils:name-from-uri($mss_uri)

    (: return a link + text to the manuscript :)
    return
        <p><a href="../../mss/{$name}/index.html">{$node//tei:repository/string()}, {$node//tei:collection/string()}, {$node//tei:idno/string()}</a></p>
};

(: Get the <msIdentifier/> for the witnesses by following xincludes under the <listBibl xml:id="witness"/> element :)
declare function dashboard-text:witnesses-includes($uri as xs:string)  {

    (: find the include nodes :)
    let $witnesses := fn:doc($uri)//tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listBibl[@xml:id='witness']/tei:bibl/xi:include

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


declare function dashboard-text:mss-identifier($file as xs:string) {

    (: get the include :)
    let $include := doc($file)//tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/xi:include

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



(: ---------- TEMPLATE FUNCTIONS ----------- :)

(: adds the full URI of the text to the map so that it can be used by the following functions  -
 : the $mss variable is passed in via the controller; it generates it from the requested
 : URL, which includes the name of the file :)
declare function dashboard-text:find-text($node as node (), $model as map (*), $text as xs:string) {
    map { "text" := concat($config:mpese-tei-corpus-texts, '/', $text) }
};

(: title of the text :)
declare %templates:wrap function dashboard-text:title($node as node (), $model as map (*)) {
    mpese-text:title($model('text'))
};

(: text type keywords :)
declare function dashboard-text:keywords-text-type($node as node (), $model as map (*), $text as xs:string) {
    dashboard-text:items-as-list(mpese-text:keywords-text-type($model('text')))
};

(: topic keywords :)
declare function dashboard-text:keywords-topic($node as node (), $model as map (*), $text as xs:string) {
    dashboard-text:items-as-list(mpese-text:keywords-topic($model('text')))
};

(: the transcript :)
declare function dashboard-text:text-body($node as node (), $model as map (*), $text as xs:string) {
    mpese-text:text-body($model('text'))
};

(: the manuscript for the text :)
declare function dashboard-text:text-mss($node as node (), $model as map (*), $text as xs:string) {
    let $mss_ident := dashboard-text:mss-identifier($model('text'))
    let $mss_uri := fn:base-uri($mss_ident)
    let $name := utils:name-from-uri($mss_uri)
        return
        <p><a href="../../mss/{$name}/index.html">{$mss_ident//tei:repository/string()}, {$mss_ident//tei:collection/string()}, {$mss_ident//tei:idno/string()}</a></p>
};

(: other witnesses for the text :)
declare function dashboard-text:witnesses($node as node (), $model as map (*), $text as xs:string)  {
 let $witnesses_inc := dashboard-text:witnesses-includes($model('text'))
 for $witness in $witnesses_inc
    return dashboard-text:mss-details($witness)
};
