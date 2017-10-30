xquery version "3.1";

module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';
import module namespace kwic="http://exist-db.org/xquery/kwic";

import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/' at 'mpese-corpus-text.xqm';
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/" at 'utils.xql';


(: ---------- SEARCHING AND PROCESSING RESULTS ---------- :)

(: Text search against the <tei:title/> of the document. Ordered by the title. :)
declare function mpese-search:search-title($query) as element()* {
    for $result in fn:collection($config:mpese-tei-corpus-texts)//tei:titleStmt/tei:title[ft:query(., $query)]
    order by $result/text()
    return $result
};

(: Search against title, author and text :)
declare function mpese-search:search($phrase) {
    for $hit in collection($config:mpese-tei-corpus-texts)/*[ft:query(.,$phrase)]
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
    for $result at $count in subsequence($results, $start, $num)
    return $result
};

(:
:~
 : Recursive function to create a formatted string of authors for a text.
 :
 : @param $label - the current label
 : @param $authors - the current sequence of authors.
 : @returns a formatted label of authors.
:)
declare %private function mpese-search:author-label-r($label as xs:string, $authors as node()*) as xs:string {

    let $auth_count := fn:count($authors)
    return
        if ($auth_count eq 1) then
            $label || functx:trim($authors[1]/string())
        else if ($auth_count eq 2) then
            let $tmp_label := $label || functx:trim($authors[1]/string()) || ', and '
            let $tmp_authors := fn:subsequence($authors, 2)
            return
                mpese-search:author-label-r($tmp_label, $tmp_authors)
        else
            let $tmp_label := $label || functx:trim($authors[1]/string()) || ', '
            let $tmp_authors := fn:subsequence($authors, 2)
            return
                mpese-search:author-label-r($tmp_label, $tmp_authors)
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
 : For a list of <author/> elements returms a formatted string of authors.
 :
 : @param $authors - sequence of <author/> elements.
 : @returns a formatted label of authors.
:)
declare function mpese-search:author-label($authors as node()*) as xs:string {

    if (fn:count($authors) eq 0) then
        ""
    else
        mpese-search:author-label-r("", $authors)
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
        $snippet as node()*, $mss as xs:string) as node() {
    <a href="{$link}" class="list-group-item">{
        <div class="result-entry">
            <h4 class="list-group-item-heading result-entry-title">{$title}</h4>
            <p class="list-group-item-text result-entry-author">{$author}</p>
            <p class="list-group-item-text result-entry-snippet">{$snippet}</p>
            <p class="list-group-item-text result-entry-mss"><strong>{$mss}</strong></p>
        </div>
    }</a>
};

declare function mpese-search:pagination-link($page as xs:integer, $search as xs:string?) {
    if ($search) then
        './?page=' || $page || '&amp;search=' || $search
    else
        './?page=' || $page
};

declare function mpese-search:pagination($page, $pages, $search, $label) {
    <nav id="paginaton" aria-label="{$label}">
        <div class="text-center">
            <ul class="pagination">
                {
                    if ($page eq 1) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Previous</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($page - 1, $search)}">Previous</a></li>
                }
                {
                    for $count in 1 to $pages
                        return
                            if ($count eq $page) then
                                <li class="page-item active"><a class="page-link" href="{mpese-search:pagination-link($count, $search)}">{$count}</a></li>
                            else
                                <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($count,$search)}">{$count}</a></li>
                }
                {
                    if ($page eq $pages) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Next</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($page + 1, $search)}">Next</a></li>
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
declare function mpese-search:titles($page as xs:integer, $num as xs:integer)  {

    let $start := mpese-search:seq-start($page, $num)
    let $query := '*:*'

    let $sorted-results := mpese-search:search-title($query)

    let $total := fn:count($sorted-results)
    let $pages := mpese-search:pages-total($total, $num)

    let $results := mpese-search:paginate-results($sorted-results, $start, $num)
    return

    <div id="search-results">
        <p class="text-center results-total">{$total} texts available</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, "", "Top navigation")
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
                                        $mss/tei:repository/string() || ', ' || $mss/tei:collection/string() || ', '
                                                || $mss/tei:idno/string() else '')
                let $author-label := mpese-search:author-label($authors)
                let $text := doc($uri)//tei:text[1]/tei:body/tei:p[1]/string()
                let $link := './t/' || $name || '.html'
                let $snippet := <em>{fn:substring($text, 1, 200)} ...</em>
                return mpese-search:result-entry($link, $title, $author-label, $snippet, $mss-label)
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, "", "Bottom navigation")
            else
                ""
        }
    </div>
};

(: default search, i.e. no search results defined  :)
declare function mpese-search:everything($page as xs:integer, $num as xs:integer, $search as xs:string)  {

    (: unpaginated results:)
    let $sorted-results := mpese-search:search($search)

    (: work out pagnation :)
    let $start := mpese-search:seq-start($page, $num)
    let $total := fn:count($sorted-results)
    let $pages := mpese-search:pages-total($total, $num)
    let $results := mpese-search:paginate-results($sorted-results, $start, $num)

    return

    <div id="search-results">
        <p class="text-center results-total">{$total} texts available</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $search, "Top navigation")
            else
                ""
        }
        <div class="list-group">{

            for $item in $results
                let $uri := fn:base-uri($item)
                let $name := utils:name-from-uri($uri)
                let $title := mpese-search:result-title($item)
                let $authors := $item//tei:fileDesc/tei:titleStmt/tei:author
                let $mss-include := $item//tei:sourceDesc/tei:msDesc/xi:include
                let $mss := mpese-text:mss-details-include($mss-include)
                let $mss-label := ( if (fn:string-length($mss/string()) > 0) then
                                        $mss/tei:repository/string() || ', ' || $mss/tei:collection/string() || ', '
                                                || $mss/tei:idno/string() else '')
                let $author-label := mpese-search:author-label($authors)
                let $link := './t/' || $name || '.html'
                let $snippet := mpese-search:matches($item)
                return mpese-search:result-entry($link, $title, $author-label, $snippet, $mss-label)
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $search, "Bottom navigation")
            else
                ""
        }
    </div>
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
    function mpese-search:default($node as node (), $model as map (*), $page as xs:integer, $num as xs:integer,
                                  $search as xs:string)  {

    if (fn:string-length($search) eq 0) then
        mpese-search:titles($page, $num)
    else
        mpese-search:everything($page, $num, $search)

};

