xquery version "3.1";

module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

import module namespace kwic='http://exist-db.org/xquery/kwic';
import module namespace request="http://exist-db.org/xquery/request";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/' at 'mpese-corpus-text.xqm';
import module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/' at 'mpese-corpus-mss.xqm';
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/" at 'utils.xql';


(: ---------- SEARCHING AND PROCESSING RESULTS ---------- :)

(: Text search against the <tei:title/> of the document. Ordered by the title. :)
declare function mpese-search:all() as element()* {
    for $result in fn:collection($config:mpese-tei-corpus-texts)//tei:TEI[tei:text[not(@type) or @type='mpese_text']]
    order by $result//tei:titleStmt/tei:title/text()
    return $result
};

(: Search against title, author and text :)
declare function mpese-search:search($phrase) {
    collection($config:mpese-tei-corpus-texts)/*[ft:query(.,$phrase)][tei:text[not(@type) or @type='mpese_text']]
};

declare function mpese-search:search($phrase, $results_order) {
    if ($results_order eq 'date') then
        for $hit in mpese-search:search($phrase)
        let $date := $hit//tei:profileDesc/tei:creation/tei:date[1]/@when/string()
        order by $date ascending
        return $hit
    else
        for $hit in mpese-search:search($phrase)
        let $score := ft:score($hit)
        order by $score descending
        return $hit
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
    for $result in subsequence($results, $start, $num)
    return $result
};

(:
:~
 : Calculate the starting point in a sequence of results based on the current page.
 :
 : @param $page - the current page.
 : @param $num - items per page
 : @returns the starting point in a sequence.
:)
declare function mpese-search:seq-start($page as xs:integer, $num as xs:integer) as xs:integer {
    ($page * $num) - ($num - 1)
};

(:
:~
 : Calculate the total number of pages based on the results.
 :
 : @param $total - the number of results.
 : @param $num - items per page
 : @returns the number of page needed for pagination.
:)
declare function mpese-search:pages-total($total as xs:integer, $num as xs:integer) as xs:integer {
    xs:integer(fn:ceiling($total div $num))
};

(: ---------- DATA RENDERING ---------- :)

(:
:~
 : Create a title for the search results
 :
 : @param $doc - the TEI/XML document
 : @returns a formatted title
:)
declare function mpese-search:result-title($doc) {
    let $tmp_title := $doc//tei:fileDesc/tei:titleStmt/tei:title/string()
    let $tmp_date := $doc//tei:profileDesc/tei:creation/tei:date[1]/string()
    let $title := ( if (fn:string-length($tmp_title) > 0) then $tmp_title else fn:string('Untitled') )
    let $date  := ( if (fn:string-length($tmp_date) > 0) then $tmp_date else fn:string('No date') )
    return
        concat($title, ' (', $date, ')')

};

(:
:~
 : Return a formatted result item.
 :
 : @param $link - a link to the full text item
 : @param $title - the title of the item
 : @param $author - the author(s)
 : @param $snippet - preview of matching text
 : @param $mss - the manuscript the text is from
 : @returns a formatted result item
:)
declare function mpese-search:result-entry($link as xs:string, $title as xs:string, $author as xs:string*,
        $snippet as node()*, $mss as xs:string, $images as node()*) as node() {
    <a href="{$link}" class="list-group-item">{
        <div class="result-entry">
            <h4 class="list-group-item-heading result-entry-title">{$title}{$images}</h4>
            <p class="list-group-item-text result-entry-author">{$author}</p>
            <p class="list-group-item-text result-entry-snippet">{$snippet}</p>
            <p class="list-group-item-text result-entry-mss"><strong>{$mss}</strong></p>
        </div>
    }</a>
};

declare function mpese-search:pagination-link($page, $map) {
    let $params := for $key in map:keys($map)
        return $key || '=' || encode-for-uri($map($key))
    return
        './?page=' || $page || '&amp;' || string-join($params, '&amp;')
};

declare function mpese-search:pagination($page, $pages, $map, $label) {
    <nav id="paginaton" aria-label="{$label}">
        <div class="text-center">
            <ul class="pagination">
                {
                    if ($page eq 1) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Previous</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($page - 1, $map)}">Previous</a></li>
                }
                {
                    for $count in 1 to $pages
                        return
                            if ($count eq $page) then
                                <li class="page-item active"><a class="page-link" href="{mpese-search:pagination-link($count, $map)}">{$count}</a></li>
                            else
                                <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($count,$map)}">{$count}</a></li>
                }
                {
                    if ($page eq $pages) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Next</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($page + 1, $map)}">Next</a></li>
                }
            </ul>
        </div>
     </nav>
};

declare function mpese-search:matches($result) {
    let $matches := kwic:summarize($result, <config width="40"/>)
    return
        for $match in $matches
        return $match//*
};


(: default search, i.e. no search results defined  :)
declare function mpese-search:all($page as xs:integer, $num as xs:integer)  {

    let $start := mpese-search:seq-start($page, $num)
    let $sorted-results := mpese-search:all()
    let $total := fn:count($sorted-results)
    let $pages := mpese-search:pages-total($total, $num)
    let $results := mpese-search:paginate-results($sorted-results, $start, $num)
    let $message := if ($total eq 1) then $total || ' text available' else $total || " texts available"

    return
        ( response:set-cookie('mpese-search-string', ''), response:set-cookie('mpese-search-page', $page),
          response:set-cookie('mpese-search-order', ''),
    <div id="search-results">
        <p class="text-center results-total">{$message}</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, map {}, "Top navigation")
            else

                ""
        }
        <div class="list-group">{


            for $item in $results
                let $uri := fn:base-uri($item)
                let $name := utils:name-from-uri($uri)
                let $title := mpese-text:title-label($item)
                let $authors := $item//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
                let $mss := mpese-text:mss-details($item)
                let $mss-label := mpese-mss:ident-label($mss)
                let $author-label := mpese-text:author-label($authors)
                let $text := doc($uri)//tei:text[1]/tei:body/tei:p[1]/string()
                let $link := './t/' || $name || '.html'
                let $snippet := <em>{fn:substring($text, 1, 200)} ...</em>
                let $images := if (count($item//tei:facsimile/tei:graphic) > 0) then
                    (text{' '}, <span class="glyphicon glyphicon-camera" aria-hidden="true"></span>,
                    <span class="sr-only">Images available</span>) else ()
                return mpese-search:result-entry($link, $title, $author-label, $snippet, $mss-label, $images)
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, map {}, "Bottom navigation")
            else
                ""
        }
    </div>)
};

(: default search, i.e. no search results defined  :)
declare function mpese-search:everything($page as xs:integer, $num as xs:integer, $search as xs:string, $results_order as xs:string)  {

    (: unpaginated results:)
    let $sorted-results := mpese-search:search($search, $results_order)

    (: work out pagnation :)
    let $start := mpese-search:seq-start($page, $num)
    let $total := fn:count($sorted-results)
    let $pages := mpese-search:pages-total($total, $num)
    let $results := mpese-search:paginate-results($sorted-results, $start, $num)
    let $message := if ($total eq 1) then $total || ' text available' else $total || " texts available"
    let $map := map { 'search' := $search, 'results_order' := $results_order }

    return
        (response:set-cookie('mpese-search-string', util:base64-encode($search)),
         response:set-cookie('mpese-search-page', $page), response:set-cookie('mpese-search-order', $results_order),
    <div id="search-results">
        <p class="text-center results-total">{$message}</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $map, "Top navigation")
            else
                ""
        }
        <div class="list-group">{

            for $item in $results
                let $uri := fn:base-uri($item)
                let $name := utils:name-from-uri($uri)
                let $title := mpese-text:title-label($item)
                let $authors :=  $item//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
                let $mss := mpese-text:mss-details($item)
                let $mss-label := mpese-mss:ident-label($mss)
                let $author-label := mpese-text:author-label($authors)
                let $link := './t/' || $name || '.html'
                let $snippet := mpese-search:matches($item)
                let $images := if (count($item//tei:facsimile/tei:graphic) > 0) then
                    (text{' '}, <span class="glyphicon glyphicon-camera" aria-hidden="true"></span>,
                    <span class="sr-only">Images available</span>) else ()
                return mpese-search:result-entry($link, $title, $author-label, $snippet, $mss-label, $images)
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $map, "Bottom navigation")
            else
                ""
        }
    </div>)
};

(: ---------- TEMPLATE FUNCTIONS ----------- :)

declare %templates:default("search", "") %templates:default("results_order", "relevance")function mpese-search:form($node as node (), $model as map (*),
        $search as xs:string, $results_order as xs:string)  {

    let $rel_order := if ($results_order eq 'relevance') then
            <input name="results_order" value="relevance" type="radio" checked="checked"/>
        else
            <input name="results_order" value="relevance" type="radio"/>

    let $date_order := if ($results_order eq 'date') then
            <input name="results_order" value="date" type="radio" checked="checked"/>
        else
            <input name="results_order" value="date" type="radio"/>
    return
    <form action="." method="get">
        <div class="input-group input-group-lg">
             <input name="search" type="text" class="form-control" placeholder="Search ..." value="{$search}" />
            <span class="input-group-btn">
                <button class="btn btn-secondary" type="submit" aria-label="Search"><span class="glyphicon glyphicon-search" aria-hidden="true"></span></button>
            </span>
        </div>
            <div>
                <p class="text-center">Order results by {$rel_order}
                    relevance or {$date_order} date. Alternatively,
                    use the <a href="">advanced search</a> or <a href="">browse</a>.</p>
            </div>
    </form>

};

(: homepage with search  :)
declare %templates:default("page", 1) %templates:default("num", 10) %templates:default("search", "")
    %templates:default("results_order", "relevance") function mpese-search:default($node as node (), $model as map (*), $page as xs:integer, $num as xs:integer,
                                  $search as xs:string, $results_order as xs:string)  {

    if (fn:string-length($search) eq 0) then
        mpese-search:all($page, $num)
    else
        (
            util:log('INFO', ('order by ' || $results_order )),
            mpese-search:everything($page, $num, $search, $results_order)
        )
};

declare function mpese-search:last-change($node as node (), $model as map (*))  {
    let $date := doc('/db/mpese/tei/corpus/meta/mpese.xml')//tei:text/tei:body/tei:div[1]/tei:head/tei:date/string()
    return
        <div class="alert alert-info text-center"><a href="./changes.html">Last updated on {$date}. See changes.</a></div>
};