xquery version "3.1";

module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/' at 'mpese-corpus-text';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/" at 'utils.xql';


declare function mpese-search:result-title($doc) {
    let $tmp_title := $doc//tei:fileDesc/tei:titleStmt/tei:title/string()
    let $tmp_date := $doc//tei:profileDesc/tei:creation/tei:date[1]/string()
    let $title := ( if (fn:string-length($tmp_title) > 0) then $tmp_title else fn:string('Untitled') )
    let $date  := ( if (fn:string-length($tmp_date) > 0) then $tmp_date else fn:string('No date') )
    return
        concat($title, ' (', $date, ')')

};

(: Text search against the <tei:title/> of the document. Ordered by the title. :)
declare function mpese-search:search-title($query) as element()* {
    for $result in fn:collection($config:mpese-tei-corpus-texts)//tei:titleStmt/tei:title[ft:query(., $query)]
    order by $result/text()
    return $result
};

(:
:~
 : Return a subset of the results to support pagination.
 :
 : @param $results - the unpaginated results.
 : @param $start - the location in the results to start the pagination.
 : @param $num - the number of results to return in the pagination.
 : @returns a subset of results.
:)
declare function mpese-search:paginate-results($results as element()*, $start as xs:int, $num as xs:int) {
    for $result at $count in subsequence($results, $start, $num)
    return $result
};


(: title of the text :)
declare function mpese-search:author-label($authors) {
    let $auth_count := fn:count($authors)
    return
        if ($auth_count > 0) then
            if ($auth_count > 1) then
                for $author at $pos in $authors
                    return
                        if ($pos eq $auth_count) then
                            concat(' and ', functx:trim($author/string()))
                        else
                            concat(functx:trim($author/string()), ', ')
            else
                if (fn:string-length($authors[1]/string()) > 0) then
                    functx:trim($authors[1]/string())
                else
                    ""
        else
            ""
};

(: ---------- HELPER FUNCTION: DATA RENDERING ---------- :)

declare function mpese-search:pagination($page, $pages, $label) {
    <nav id="paginaton" aria-label="{$label}">
        <div class="text-center">
            <ul class="pagination">
                {
                    if ($page eq 1) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Previous</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="./?page={$page - 1}">Previous</a></li>
                }
                {
                    for $count in 1 to $pages
                        return
                            if ($count eq $page) then
                                <li class="page-item active"><a class="page-link" href="./?page={$count}">{$count}</a></li>
                            else
                                <li class="page-item"><a class="page-link" href="./?page={$count}">{$count}</a></li>
                }
                {
                    if ($page eq $pages) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Next</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="./?page={$page + 1}">Previous</a></li>
                }
            </ul>
        </div>
     </nav>
};

(: ---------- TEMPLATE FUNCTIONS ----------- :)


(: default search, i.e. no search results defined  :)
declare function mpese-search:default($node as node (), $model as map (*))  {

    let $page := xs:integer(request:get-parameter("page", "1"))
    let $num := xs:integer(request:get-parameter("num", "10"))
    let $start := ($page * $num) - ($num - 1)
    let $query := '*:*'

    let $sorted-results := mpese-search:search-title($query)

    let $total := fn:count($sorted-results)
    let $pages := xs:integer(fn:ceiling( $total div $num))

    let $results := mpese-search:paginate-results($sorted-results, $start, $num)
    return

    <div id="search-results">
        <p class="text-center results-total">{$total} texts available</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, "Top navigation")
            else
                ""
        }
        <div class="list-group">{

            for $item in $results
                let $uri := fn:base-uri($item)
                let $name := utils:name-from-uri($uri)
                let $doc := doc($uri)
                let $title := mpese-search:result-title($doc)
                let $authors := mpese-text:authors($uri)
                let $mss := mpese-text:mss-details($uri)
                let $mss-label := ( if (fn:string-length($mss/string()) > 0) then
                                        concat($mss/tei:repository/string(), ', ', $mss/tei:collection/string(), ', ',
                                                $mss/tei:idno/string()) else '')
                let $author-label := mpese-search:author-label($authors)
                let $text := doc($uri)//tei:text[1]/tei:body/tei:p[1]/string()
                return <a href="./t/{$name}.html" class="list-group-item">{
                    <div class="result-entry">
                        <h4 class="list-group-item-heading result-entry-title">{$title}</h4>
                        <p class="list-group-item-text result-entry-author">{$author-label}</p>
                        <p class="list-group-item-text result-entry-snippet"><em>{fn:substring($text, 1, 200)} ...</em></p>
                        <p class="list-group-item-text result-entry-mss"><strong>{$mss-label}</strong></p>
                    </div>
                }</a>
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, "Bottom navigation")
            else
                ""
        }
    </div>
};