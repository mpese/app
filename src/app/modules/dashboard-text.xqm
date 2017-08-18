module namespace dashboard-text = "http://mpese.rit.bris.ac.uk/dashboard/text/";

(:
 : A Module with functions for rendering the details of a text within the researcher's
 : dashboard area. The name of the file is part of the URL, so AbbotJamesNullity1613.xml
 : appears in the dashboard URL as dashboard/text/AbbotJamesNullity1613/index.html.
 : The application controller extracts the name from the URL, appends '.xml'  and forwards
 : it to text.html
 :)

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";
import module namespace mpese-text = "http://mpese.rit.bris.ac.uk/corpus/text/" at 'mpese-corpus-text.xqm';

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

(: ---------- TEMPLATE FUNCTIONS ----------- :)

(: adds the full URI of the text to the map so that it can be used by the following functions :)
declare function dashboard-text:find-text($node as node (), $model as map (*), $text as xs:string) {
    map { "text" := concat($config:mpese-tei-corpus-texts, '/', $text) }
};

(: title of the text :)
declare %templates:wrap function dashboard-text:title($node as node (), $model as map (*)) {
    mpese-text:title($model('text'))
};

declare function dashboard-text:keywords-text-type($node as node (), $model as map (*), $text as xs:string) {
    dashboard-text:items-as-list(mpese-text:keywords-text-type($model('text')))
};

declare function dashboard-text:keywords-topic($node as node (), $model as map (*), $text as xs:string) {
    dashboard-text:items-as-list(mpese-text:keywords-topic($model('text')))
};

declare function dashboard-text:text-body($node as node (), $model as map (*), $text as xs:string) {
    mpese-text:text-body($model('text'))
};