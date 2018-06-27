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
    <results>{
        for $result in fn:collection($config:mpese-tei-corpus-texts)//tei:TEI
        order by $result//tei:titleStmt/tei:title/text()
        return
            <result uri="{fn:base-uri($result)}">
                <summary>{<em>{substring($result//tei:text[1]/tei:body/tei:p[1]/string(), 1, 200)} ...</em>}</summary>
            </result>
    }</results>
};

(:
:~
 : Query the orignal TEI/XML documents.
 :
 : @param $query - an eXist <query/> to pass to Lucene.
 : @returns a <results/> object.
:)
declare function mpese-search:search-original($query) {
    <results>{
        for $doc in fn:collection($config:mpese-tei-corpus-texts)/*[ft:query(.,$query)]
        return
            <result uri="{fn:base-uri($doc)}" score="{ft:score($doc)}">
                <summary>{mpese-search:matches($doc)}</summary>
            </result>
    }</results>
};

declare function mpese-search:search-normalized($phrase) {
    <result>{
        for $doc in fn:collection('/db/mpese/normalized/texts')/*[ft:query(.,$phrase)]
            let $uri := fn:base-uri($doc)
            let $tmp := fn:replace($uri, '/db/mpese/normalized/texts', $config:mpese-tei-corpus-texts)
            return
                <result uri="{fn:replace($tmp, '.simple', '')}" score="{ft:score($doc)}">
                    <summary>{mpese-search:matches($doc)}</summary>
                </result>
    }</result>
};


(: Search against title, author and text :)
declare function mpese-search:search($phrase) {

    if ($phrase eq '' or functx:all-whitespace($phrase)) then mpese-search:all() else
        let $query := mpese-search:build-simple-query($phrase)

        let $a :=  mpese-search:search-original($query)
        let $b :=  mpese-search:search-normalized($query)
        let $uris := distinct-values(($a/result/@uri/string(), $b/result/@uri/string()))
        return
            <results>{
                for $uri in $uris
                    let $score_a := $a/result[@uri=$uri]/@score/number()
                    let $score_b := $b/result[@uri=$uri]/@score/number()
                    return
                        <result uri="{$uri}" score="{(if ($score_a) then $score_a else 0) + (if ($score_b) then $score_b else 0)}">{
                            if (not(empty($a/result[@uri=$uri]/summary))) then
                                $a/result[@uri=$uri]/summary
                            else if (not(empty($b/result[@uri=$uri]/summary))) then
                                $b/result[@uri=$uri]/summary
                            else
                                ()
                        }</result>
            }</results>
};

declare function mpese-search:search($phrase, $results_order) {

    let $results := mpese-search:search($phrase)

    return
    <results>{
        if ($results_order eq 'date') then
            for $result in $results/result
            let $hit := fn:doc($result/@uri/fn:string())
            let $date := $hit//tei:profileDesc/tei:creation/tei:date[1]/@when/string()
            order by $date ascending
            return $result
        else
            for $result in $results/result
            order by $result/@score/string() descending
            return $result
    }</results>
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
    <results>{
        for $result in subsequence($results/result, $start, $num)
        return $result
    }</results>
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

(:~
 : Give a message on the number of results.
 :
 : @param $total - the total number of results
 : @return a suitable message
 :)
declare function mpese-search:results-message($total as xs:integer) as xs:string {
    if ($total eq 1) then $total || ' text available.' else $total || " texts available."
};

declare function mpese-search:results-edit-search-link($map) {
    let $base := './advanced.html?'
    let $params := for $key in map:keys($map)
        return $key || '=' || encode-for-uri($map($key))
    return
        $base || string-join($params, '&amp;')
};

(:~
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

(:~
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


(:// MAKE AUTHORS A METHOD:)
(:// MAKE IMAHES A METHOD:)

(:~
 : Create an application specific partial URL for rendering a text
 : @param $item - an item from a result set.
 : @return a partal app URL for a text
 :)
declare function mpese-search:text-link($item as node()) as xs:string {
    let $uri := fn:base-uri($item)
    let $name := utils:name-from-uri($uri)
    return './t/' || $name || '.html'
};

(:~
 : Do we show 'authors' who have been assigned role? This can make a long list with
 : signatories. We could update this method to filter the type of role.
 : @param $item - an item from a result set.
 : @return a partal app URL for a text
 :)
declare function mpese-search:author-list($item, $include_roles as xs:boolean) {
    if ($include_roles) then
        $item//tei:fileDesc/tei:titleStmt/tei:author
    else
        $item//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
};

declare function mpese-search:images($item) as node()* {
    if (count($item//tei:facsimile/tei:graphic) > 0) then
        (text{' '}, <span class="glyphicon glyphicon-camera" aria-hidden="true"></span>,
        <span class="sr-only">Images available</span>)
    else ()
};

declare function mpese-search:witness-count($item) as xs:string {
    let $total := count($item//tei:listBibl[@xml:id='mss_witness_generated']/tei:bibl) + number(1)
    return
        if ($total eq 1) then '1 witness' else $total || ' witnesses'
};

declare function mpese-search:result-entry($item as node(), $summary as node(), $show_kwic as xs:boolean) as node() {

    (: link to the text :)
    let $link := mpese-search:text-link($item)

    (: title to display :)
    let $title := mpese-text:title-label($item)

    (: authors to display :)
    let $authors :=  mpese-search:author-list($item, false())
    let $author-label := mpese-text:author-label($authors)

    (: mss details to display :)
    let $mss := mpese-text:mss-details($item)
    let $mss-label := mpese-mss:ident-label($mss)

    (: kiwc in snippet :)
    let $snippet := if ($show_kwic) then $summary
            else <em>{substring($item//tei:text[1]/tei:body/tei:p[1]/string(), 1, 200)} ...</em>
    let $images := mpese-search:images($item)

    (: witnesses :)
    let $witnesses := mpese-search:witness-count($item)

    return
        <a href="{$link}" class="list-group-item">{
        <div class="result-entry">
            <h4 class="list-group-item-heading result-entry-title">{$title}{$images}</h4>
            <p class="list-group-item-text result-entry-author">{$author-label}</p>
            <p class="list-group-item-text result-entry-snippet">{$snippet}</p>
            <p class="list-group-item-text result-entry-witness">{$witnesses}</p>
            <p class="list-group-item-text result-entry-mss"><strong>{$mss-label}</strong></p>
        </div>}
    </a>
};



declare function mpese-search:pagination-link($page, $map, $type) {
    let $base := if ($type eq 'adv') then './results.html?page=' else './?page='
    let $params := for $key in map:keys($map)
        return
        if ($key eq 'page') then ()
        else $key || '=' || encode-for-uri($map($key))
    return
        $base || $page || '&amp;' || string-join($params, '&amp;')
};

declare function mpese-search:pagination($page, $pages, $map, $label, $type) {
    <nav id="paginaton" aria-label="{$label}">
        <div class="text-center">
            <ul class="pagination">
                {
                    if ($page eq 1) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Previous</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($page - 1, $map, $type)}">Previous</a></li>
                }
                {
                    for $count in 1 to $pages
                        return
                            if ($count eq $page) then
                                <li class="page-item active"><a class="page-link" href="{mpese-search:pagination-link($count, $map, $type)}">{$count}</a></li>
                            else
                                <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($count,$map,$type)}">{$count}</a></li>
                }
                {
                    if ($page eq $pages) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Next</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($page + 1, $map, $type)}">Next</a></li>
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

declare function mpese-search:cookies($type, $map) {
    response:set-cookie('mpese-search-type', $type),
    for $key in map:keys($map)
        return response:set-cookie('mpese-search-' || $key, util:base64-encode(($map($key))))
};

(: default search, i.e. no search results defined  :)
declare function mpese-search:all($page as xs:integer, $num as xs:integer)  {

    let $start := mpese-search:seq-start($page, $num)
    let $sorted-results := mpese-search:all()
    let $total := fn:count($sorted-results/result)
    let $pages := mpese-search:pages-total($total, $num)
    let $results := mpese-search:paginate-results($sorted-results, $start, $num)
    let $message := if ($total eq 1) then $total || ' text available' else $total || " texts available"

    return
        ( response:set-cookie('mpese-search-search', util:base64-encode('')), response:set-cookie('mpese-search-page', util:base64-encode($page)),
          response:set-cookie('mpese-search-order', util:base64-encode('')), response:set-cookie('mpese-search-type', 'basic'),
    <div id="search-results">
        <p class="text-center results-total">{$message}</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, map {}, "Top navigation", 'basic')
            else

                ""
        }
        <div class="list-group">{

            for $result in $results/result
                let $uri := $result/@uri/fn:string()
                let $item := doc($uri)/tei:TEI
                let $name := utils:name-from-uri($uri)
                let $title := mpese-text:title-label($item)
                let $authors := $item//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
                let $mss := mpese-text:mss-details($item)
                let $mss-label := mpese-mss:ident-label($mss)
                let $author-label := mpese-text:author-label($authors)
                let $text := doc($uri)//tei:text[1]/tei:body/tei:p[1]/string()
                let $link := './t/' || $name || '.html'
                let $snippet := <em>{fn:substring($text, 1, 200)} ...</em>
                let $images := if (exists($item//tei:facsimile/tei:graphic/@n)) then
                    (text{' '}, <span class="glyphicon glyphicon-camera" aria-hidden="true"></span>,
                    <span class="sr-only">Images available</span>) else ()
                return mpese-search:result-entry($link, $title, $author-label, $snippet, $mss-label, $images)
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, map {}, "Bottom navigation", "basic")
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
    let $total := fn:count($sorted-results/result)
    let $pages := mpese-search:pages-total($total, $num)
    let $results := mpese-search:paginate-results($sorted-results, $start, $num)
    let $message := if ($total eq 1) then $total || ' text available' else $total || " texts available"
    let $map := map { 'search' := $search, 'results_order' := $results_order }

    return
        (response:set-cookie('mpese-search-search', util:base64-encode($search)),
         response:set-cookie('mpese-search-page', util:base64-encode($page)), response:set-cookie('mpese-search-order', util:base64-encode($results_order)),
         response:set-cookie('mpese-search-type', 'basic'),
    <div id="search-results">
        <p class="text-center results-total">{$message}</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $map, "Top navigation", "basic")
            else
                ""
        }
        <div class="list-group">{

            for $result in $results/result
                let $uri := $result/@uri/fn:string()
                let $item := doc($uri)/tei:TEI
                let $name := utils:name-from-uri($uri)
                let $title := mpese-text:title-label($item)
                let $authors :=  $item//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
                let $mss := mpese-text:mss-details($item)
                let $mss-label := mpese-mss:ident-label($mss)
                let $author-label := mpese-text:author-label($authors)
                let $link := './t/' || $name || '.html'
                let $snippet := $result/summary
                let $images := if (count($item//tei:facsimile/tei:graphic) > 0) then
                    (text{' '}, <span class="glyphicon glyphicon-camera" aria-hidden="true"></span>,
                    <span class="sr-only">Images available</span>) else ()
                return mpese-search:result-entry($link, $title, $author-label, $snippet, $mss-label, $images)
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $map, "Bottom navigation", "basic")
            else
                ""
        }
    </div>)
};


declare function mpese-search:build-query-term($token, $type) {
    let $elmnt :=   if (fn:ends-with($token, '~')) then
                        let $length := fn:string-length($token)
                        return
                            if ($length eq 1) then ()
                            else <fuzzy>{fn:substring($token, 1, ($length - 1))}</fuzzy>
                    else if (contains($token, '*')) then <wildcard>{$token}</wildcard>
                    else <term>{$token}</term>
    return
        if ($elmnt and $type eq 'all') then
            element { node-name($elmnt) } {attribute { 'occur' } { 'must'}, $elmnt/string()}
        else
        $elmnt
};

(: wrap a search query in eXist's XML wrapper :)
declare function mpese-search:build-query($phrase, $type, $exclude) {

    (: tokenize the strings - clean up whitespace :)
    let $search_tokens := fn:tokenize(fn:normalize-space(fn:lower-case($phrase)), '\s+')
    let $exclude_tokens := fn:tokenize(fn:normalize-space(fn:lower-case($exclude)), '\s+')
    let $query :=
        <query>{
            (: wildcard search all for white space :)
            if (fn:empty($search_tokens)) then
                ()
            else
                if ($type eq 'phrase') then
                    <phrase>{fn:string-join($search_tokens, ' ')}</phrase>
                else
                    <bool>{
                        for $token in $search_tokens
                            return mpese-search:build-query-term($token, $type)
                    } {
                        for $token in $exclude_tokens
                            return
                                <term occur="not">{$token}</term>
                    }</bool>
        }</query>
    return $query
};

(:
:~
 : Create query XML for a simple search.
 :
 : @param $phrase - original search phrase.
 : @returns XML for a lucene query.
:)
declare function mpese-search:build-simple-query($phrase) {

    (: :)
    let $tmp := fn:normalize-space(fn:lower-case($phrase))
    return
        if (fn:starts-with($tmp, '"') and fn:ends-with($tmp, '"')) then
            mpese-search:build-query(fn:replace($tmp, '"', ''), 'phrase', ())
        else
            let $tokens := for $token in fn:tokenize($tmp) return
                                if (not(fn:ends-with($token, '*')) and not(fn:ends-with($token, '~'))) then
                                    $token || '*' else $token
            return mpese-search:build-query(fn:string-join($tokens, ' '), (), ())
};

(: get a list of available text types:)
declare function mpese-search:keywords-list() {

    (: everything :)
    let $text-types := collection($config:mpese-tei-corpus-texts)//tei:keywords[@n='text-type']/tei:term/string()

    (: return ordred unique values, ignoring case :)
    return
        for $key in distinct-values($text-types) order by lower-case($key)
        return if (not($key eq '')) then $key else ()

};

(: get a list of available languages :)
declare function mpese-search:languages() {
    for $lang in distinct-values(collection($config:mpese-tei-corpus-texts)//tei:langUsage/tei:language/string())
    order by $lang return if (not($lang eq "")) then $lang else ()
};

(: get a list of repositories :)
declare function mpese-search:repositories() {
    for $repo in distinct-values(collection($config:mpese-tei-corpus-mss)//tei:repository)
    order by $repo return if ($repo = "") then () else $repo
};

declare function mpese-search:advanced($phrase, $type, $exclude, $image, $start-range, $end-range, $order-by) {

    (: construct the query xml: will be pulled in via util:eval :)
    (: unfiltered results :- parsed in the eval statement at the botton :)
    let $results := if ($phrase eq '' or functx:all-whitespace($phrase)) then mpese-search:all()
        else let $query := mpese-search:build-query($phrase, $type, $exclude)
            return mpese-search:search($query)

    (:::: we create the search as strings that can be evaluated ::::)

    (: we are filtering of <result/> objects :)
    let $results_predicate := "for $result in $results/result "

    (: need the doc of each result :)
    let $doc_predicate := "let $doc := doc($result/@uri/string()) "

    (: we need the date of the doc :)
    let $date_predicate := "let $date := '' "

    (: are we filtering for images :)
    let $image_predicate := if ($image eq 'yes') then "exists($doc//tei:facsimile) " else ()

    (: start date? :)
    let $start_date := if (not($start-range eq '' or empty($start-range))) then "number($date) >= number($start-range)" else ()

    (: end date? :)
    let $end_date := if (not($end-range eq '' or empty($end-range))) then "number($date) <= number($end-range)" else ()

    (: date filter :)
    let $date_filter := if (not(empty($start_date) or empty($end_date))) then fn:string-join(($start_date, $end_date) , ' and ') else ()

    (: might be filtering on date and images :)
    let $where_filter := fn:string-join(($date_filter, $image_predicate), ' and ')

    (: where predicate :)
    let $where_predicate := if ($where_filter) then 'where ' || $where_filter else ()

    (: order by :)
    let $order_by_predicate := if ($order-by eq 'date_d') then ' order by $date descending '
                               else if ($order-by eq 'witness_d') then ' order by count($doc//tei:listBibl[@xml:id="mss_witness_generated"]/tei:bibl) descending '
                               else if ($order-by eq 'witness_a') then ' order by count($doc//tei:listBibl[@xml:id="mss_witness_generated"]/tei:bibl) ascending '
                               else ' order by $date ascending '

    let $return_predicate := " return if ($doc) then $result else ()"

    let $query2 := concat($results_predicate, $doc_predicate, $date_predicate, $where_predicate, $order_by_predicate, $return_predicate)

    let $return_results := <results>{util:eval($query2)}</results>

    return $return_results
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
                    use the <a href="./advanced.html">advanced search</a>.</p>
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
        mpese-search:everything($page, $num, $search, $results_order)
};

declare function mpese-search:last-change($node as node (), $model as map (*))  {
    let $date := doc('/db/mpese/tei/corpus/meta/mpese.xml')//tei:text/tei:body/tei:div[1]/tei:head/tei:date/string()
    return
        <div class="alert alert-info text-center"><a href="./changes.html">Last updated on {$date}. See changes.</a></div>
};


declare
%templates:default("search", "")
%templates:default("type", "any")
%templates:default("exclude", "")
%templates:default("start-range", "")
%templates:default("end-range", "")
%templates:default("image", "no")
%templates:default("order-by", 'date_a')
function mpese-search:advanced-form($node as node (), $model as map (*),
        $search as xs:string, $type as xs:string, $exclude as xs:string, $start-range as xs:string,
        $end-range as xs:string, $image as xs:string, $order-by as xs:string)  {

    let $input_any := if ($type eq 'any') then <input type="radio" name="type" id="adv_search_type1" value="any" checked="checked"/>
                      else <input type="radio" name="type" id="adv_search_type1" value="any"/>

    let $input_all := if ($type eq 'all') then <input type="radio" name="type" id="adv_search_type2" value="all" checked="checked"/>
                      else <input type="radio" name="type" id="adv_search_type2" value="all"/>

    let $input_phrase := if ($type eq 'phrase') then <input type="radio" name="type" id="adv_search_type3" value="phrase" checked="checked"/>
                         else <input type="radio" name="type" id="adv_search_type3" value="phrase"/>

    let $text_with_images := if ($image eq 'yes') then <input type="checkbox" name="image" id="adv_image_only" value="yes" checked="checked"/>
                             else <input type="checkbox" name="image" id="adv_image_only" value="yes"/>

    let $date_asc := if ($order-by eq 'date_a') then <input type="radio" name="order-by" value="date_a" checked="checked"/>
                     else <input type="radio" name="order-by" value="date_a"/>

    let $date_desc := if ($order-by eq 'date_d') then <input type="radio" name="order-by" value="date_d" checked="checked"/>
                      else <input type="radio" name="order-by" value="date_d"/>

    let $witness_desc := if ($order-by eq 'witness_d') then <input type="radio" name="order-by" value="witness_d" checked="checked"/>
                         else <input type="radio" name="order-by" value="witness_d"/>

    let $witness_asc := if ($order-by eq 'witness_a') then <input type="radio" name="order-by" value="witness_a" checked="checked"/>
                        else <input type="radio" name="order-by" value="witness_a"/>

    return

    <form action="./results.html" method="get" class="form-horizontal">

        <div class="form-group">
            <label for="search-terms" class="col-sm-2">Keywords</label>
            <div class="col-sm-5">
                <input id="search-terms" name="search" type="text" class="form-control"
                       placeholder="keywords to search" value="{$search}" />
                <label class="radio-inline">{$input_any} match any</label>
                <label class="radio-inline">{$input_all} match all</label>
                <label class="radio-inline">{$input_phrase} match phrase</label>
            </div>
        </div>

        <div class="form-group">
            <label for="exclude-terms" class="col-sm-2">Exclude</label>
            <div class="col-sm-5">
                <input id="exclude-terms" name="exclude" type="text" class="form-control"
                       placeholder="keywords to exclude" value="{$exclude}" />
            </div>
        </div>

        <div class="form-group">
            <label class="col-sm-2">Date range</label>
            <div class="col-sm-5">
                From year <input id="start-range" name="start-range" type="text"
                            placeholder="1603" value="{$start-range}" size="4" maxsize="4" pattern="^\d{{4}}$"/> to year
                <input id="end-range" name="end-range" type="text" size="4" maxsize="4"
                       placeholder="1642" value="{$end-range}" pattern="^\d{{4}}$"/>
            </div>
        </div>

        <div class="form-group">
            <label class="col-sm-2">Order by</label>
            <div class="col-sm-5">
                <label class="radio-inline">{$date_asc} date (ascending)</label>
                <label class="radio-inline">{$date_desc} date (descending)</label><br/>
                <label class="radio-inline">{$witness_desc} no. of witnesses (descending)</label>
                <label class="radio-inline">{$witness_asc} no. of witnesses (ascending)</label>
            </div>
        </div>

        <div class="form-group">
            <div class="col-sm-2"></div>
            <div class="col-sm-5">
                <label class="checkbox-inline">
                    {$text_with_images} show only texts with images
                </label>
            </div>
        </div>
        <div class="form-group">
            <div class="col-sm-12">
                <input type="submit" value="Search"/>
            </div>
        </div>
    </form>

};

declare
%templates:default("page", 1)
%templates:default("num", 10)
%templates:default("search", "")
%templates:default("type", "any")
%templates:default("exclude", "")
%templates:default("start-range", "")
%templates:default("end-range", "")
%templates:default("image", "no")
%templates:default("order-by", 'date_a')
function mpese-search:advanced-results($node as node (), $model as map (*), $page as xs:integer, $num as xs:integer,
        $search as xs:string, $type as xs:string, $exclude as xs:string, $start-range as xs:string,
        $end-range as xs:string, $image as xs:string, $order-by as xs:string)  {

    (: kwic on wildcard everything kills the app :)
    let $show_kwic := if ($search eq '') then false() else true()

    (: all results, unpaginated :)
    let $results := mpese-search:advanced($search, $type, $exclude, $image, $start-range, $end-range, $order-by)

    (: total number :)
    let $total := count($results/result)

    (: message about results :)
    let $message := mpese-search:results-message($total)

    (:work out pagination :)
    let $start := mpese-search:seq-start($page, $num)
    let $pages := mpese-search:pages-total($total, $num)
    let $pag_results := mpese-search:paginate-results($results, $start, $num)

    (:track search parameters :)
    let $map := map { 'search' := $search, 'type' := $type, 'exclude' := $exclude, 'start-range' := $start-range,
                      'end-range' := $end-range, 'image' := $image, 'order-by' := $order-by, 'page' := $page }

    (: edit form link :)
    let $edit-link := mpese-search:results-edit-search-link($map)

    return
    (mpese-search:cookies('adv', $map),
    <div id="search-results">
        <p class="text-center results-total">{$message, text{" "}} <a href="{$edit-link}">Edit search</a>.</p>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $map, "Top navigation", "adv")
            else
                ""
        }
        <div class="list-group">{
            for $r in $pag_results/result
                let $uri := $r/@uri/fn:string()
                let $item := doc($uri)/tei:TEI
                return mpese-search:result-entry($item, $r/summary, $show_kwic)}
        </div>
    </div>)
};