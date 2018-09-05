xquery version "3.1";

module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace ft = 'http://exist-db.org/xquery/lucene';
import module namespace kwic = 'http://exist-db.org/xquery/kwic';
import module namespace util = 'http://exist-db.org/xquery/util';
import module namespace templates = 'http://exist-db.org/xquery/templates';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/' at 'mpese-corpus-text.xqm';
import module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/' at 'mpese-corpus-mss.xqm';
import module namespace utils = 'http://mpese.rit.bris.ac.uk/utils/' at 'utils.xql';


(: ---------- CONSTRUCT FREE TEXT SEARCH ---------- :)

(:~
 :  Build a suitable search term for a token. If the keyword ends in ~ then <fuzzy/> or * then
 :  <wildcard/>, otherwise <term/>. Add an attribute if needed.
 :
 : @param $token – a keyword token
 : @param $type – keyword search tyle ('all', 'any', 'phrase')
 :)
declare function mpese-search:build-query-term($token as xs:string, $type as xs:string) as node() {
    let $elmnt :=   if (fn:ends-with($token, '~')) then
                        let $length := fn:string-length($token)
                        return
                            if ($length eq 1) then ()
                            else <fuzzy>{fn:substring($token, 1, ($length - 1))}</fuzzy>
                    else if (fn:contains($token, '*')) then <wildcard>{$token}</wildcard>
                    else <term>{$token}</term>
    return
        if ($elmnt and $type eq 'all') then
            element { node-name($elmnt) } {attribute { 'occur' } { 'must'}, $elmnt/string()}
        else
        $elmnt
};

(:~
 : Build an XML object so we can query Lucene.
 :
 : @param $phrase – the search phrase
 : @param $type – keyword search tyle ('all', 'any', 'phrase')
 : @param $exclude – words to exclude
 : @return a Lucene XML object
 :)
declare function mpese-search:build-query($phrase as xs:string?, $type as xs:string?, $exclude as xs:string?) as node() {
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
    return ($query, util:log('INFO', ($query)))
};

(:~
 : For a simple search we want to do a wildcard search unless it has already been specified (and fuzzy)
 :
 : @param the search string
 : @return a (possibly) modified search string
 :)
declare function mpese-search:process-simple-search($search as xs:string) as xs:string {

    let $tmp := fn:normalize-space($search)
    return
        if (fn:string-length($search) < 3) then
            $search
        else
            let $tokens := for $t in fn:tokenize($tmp) return
                                if (fn:ends-with($t, '*') or fn:ends-with($t, '~')) then $t else $t || '*'
            return fn:string-join($tokens, ' ')
};

(: ---------- SEARCHING AND PROCESSING RESULTS ---------- :)

(:~
 : Pull out all of the texts and create a <results/> object. If there is no transcript, such as in the
 : 'placeholder' texts, then return as empty sequence rather than provide a <summary/>.
 :
 : @return a <results/> node.
 :)
declare function mpese-search:all() as node() {
    <results>{
        for $result in fn:collection($config:mpese-tei-corpus-texts)
        order by fn:replace($result//tei:titleStmt/tei:title/fn:string(), '^((A|The)\s*)', '')
        return
            <result uri="{fn:base-uri($result)}">
                {
                    let $val := fn:substring($result//tei:text[1]/tei:body/tei:p[1]/string(), 1, 200)
                    return if (fn:not(fn:normalize-space($val) eq '')) then <summary><p><em>{$val}</em> ...</p></summary> else ()
                }
            </result>
    }</results>
};

(:~
 : Query the orignal TEI/XML documents.
 :
 : @param $query - an eXist <query/> to pass to Lucene.
 : @return <results/> object.
:)
declare function mpese-search:search-original($query as node()) as node() {
    let $results :=
        <results>{
            for $doc in fn:collection($config:mpese-tei-corpus-texts)/*[ft:query(.,$query)]
            return
                <result uri="{fn:base-uri($doc)}" score="{ft:score($doc)}">
                    <summary>{mpese-search:matches($doc)}</summary>
                </result>
        }</results>
    return $results
};

(:~
 : Query the normalized TEI/XML documents.
 :
 : @param $query - an eXist <query/> to pass to Lucene.
 : @return <results/> object.
:)
declare function mpese-search:search-normalized($query as node()) as node() {
    let $results :=
        <result>{
            for $doc in fn:collection($config:mpese-normalized-texts)/*[ft:query(.,$query)]
                let $uri := fn:base-uri($doc)
                let $tmp := fn:replace($uri, $config:mpese-normalized-texts, $config:mpese-tei-corpus-texts)
                return
                    <result uri="{fn:replace($tmp, '.simple', '')}" score="{ft:score($doc)}">
                        <summary>{mpese-search:matches($doc)}</summary>
                    </result>
        }</result>
    return $results
};


(:~
 : Search the corpus using a free text search. We search the originals AND then the normalized texts.
 : We then merge the results. Lucky the corpus is small ¯\_(ツ)_/¯
 :
 : @param $query – search query (XML)
 : @return resultts
 :)
declare function mpese-search:search($query as node()) as node() {

        let $a :=  mpese-search:search-original($query)
        let $b :=  mpese-search:search-normalized($query)
        let $uris := distinct-values(($a/result/@uri/string(), $b/result/@uri/string()))
        let $results :=
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
        return $results
};

(:~
 : Do a search. We do an initial free text search against the corpus and then filter the results
 : before rendering them. The query gets quite complex, so we create the query as a string and
 : then use the eXist's eval function.
 :
 : @param $phrase – the search keywords
 : @param $keyword-type – type of keyword search (all, any, phrase)
 : @param $exclude – keywords to exclude
 : @param $image – filter on images
 : @param $transcript – filter on transcript
 : @param $start-range – start year
 : @param $end-range – end year
 : @param $order-by – order by date etc.
 : @return search results
 :)
declare function mpese-search:advanced($phrase as xs:string, $keyword-type as xs:string, $exclude as xs:string,
                                       $image as xs:string, $transcript as xs:string, $start-range as xs:string,
                                       $end-range as xs:string, $order-by as xs:string) as node() {

    (: construct the query xml: will be pulled in via util:eval :)
    (: unfiltered results :- parsed in the eval statement at the botton :)
    let $results := if ($phrase eq '' or functx:all-whitespace($phrase)
            or fn:string-length(fn:normalize-space($phrase)) < 3) then mpese-search:all()
        else let $query := mpese-search:build-query($phrase, $keyword-type, $exclude)
            return (mpese-search:search($query), util:log('INFO', ($query)))

    (:::: we create the search as strings that can be evaluated ::::)

    (: we are filtering of <result/> objects :)
    let $results_predicate := "for $result in $results/result "

    (: need the doc of each result :)
    let $doc_predicate := "let $doc := doc($result/@uri/string()) "

    (: we need the date of the doc :)
    let $date_predicate := "let $date := substring($doc//tei:creation/tei:date[1]/@when/string(), 1, 4) "

    (: are we filtering for images :)
    let $image_predicate := if ($image eq 'yes') then "exists($doc//tei:facsimile) " else ()

    (: are we filtering for available transcript :)
    let $transcript_predicate := if ($transcript eq 'yes') then "fn:string-length(fn:normalize-space($doc//tei:text[1]/tei:body[1]/string())) > 0 " else ()

    (: start date? :)
    let $start_date := if (fn:not($start-range eq '' or fn:empty($start-range)) and functx:is-a-number($start-range))
        then "number($date) >= number($start-range)" else ()

    (: end date? :)
    let $end_date := if (fn:not($end-range eq '' or fn:empty($end-range)) and functx:is-a-number($end-range))
        then "number($date) <= number($end-range)" else ()

    (: date filter :)
    let $date_filter := if (fn:not(empty($start_date) or fn:empty($end_date)))
        then fn:string-join(($start_date, $end_date) , ' and ') else ()

    (: might be filtering on date and images :)
    let $where_filter := fn:string-join(($date_filter, $image_predicate, $transcript_predicate), ' and ')

    (: where predicate :)
    let $where_predicate := if ($where_filter) then 'where ' || $where_filter else ()

    (: order by :)
    let $order_by_predicate := (if ($order-by eq 'relevance') then ' order by $result/@score/string() descending'
                               else if ($order-by eq 'date_d') then ' order by $date descending'
                               else if ($order-by eq 'witness_d') then ' order by count($doc//tei:listBibl[@xml:id="mss_witness_generated"]/tei:bibl) descending'
                               else if ($order-by eq 'witness_a') then ' order by count($doc//tei:listBibl[@xml:id="mss_witness_generated"]/tei:bibl) ascending'
                               else ' order by $date ascending') || ', fn:replace($result//tei:titleStmt/tei:title/fn:string(), "^((A|The)\s*)", "") '

    let $return_predicate := " return if ($doc) then $result else ()"

    let $query2 := concat($results_predicate, $doc_predicate, $date_predicate, $where_predicate, $order_by_predicate, $return_predicate)

    let $return_results := <results>{(util:eval($query2, fn:true()), util:log('INFO', ($query2)))}</results>

    return ($return_results, util:log('INFO', ($order-by)))
};


(:~
 : Return a subset of the results to support pagination.
 :
 : @param $results - the unpaginated results.
 : @param $start - the location in the results to start the pagination.
 : @param $num - the number of results to return in the pagination.
 : @returns a subset of results.
:)
declare function mpese-search:paginate-results($results as element()*, $start as xs:int, $num as xs:int) as node() {
    <results>{
        for $result in subsequence($results/result, $start, $num)
        return $result
    }</results>
};

(:~
 : Calculate the starting point in a sequence of results based on the current page.
 :
 : @param $page - the current page.
 : @param $num - items per page
 : @returns the starting point in a sequence.
:)
declare function mpese-search:seq-start($page as xs:integer, $num as xs:integer) as xs:integer {
    ($page * $num) - ($num - 1)
};

(:~
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
 : @param $witneses – number of witnesses
 : @returns a formatted result item
:)
declare function mpese-search:result-entry($link as xs:string, $title as xs:string, $author as xs:string*,
                                           $snippet, $mss as xs:string, $images as node()*,
                                           $transcripts as node()*, $witnesses as xs:string) as node() {
    <a href="{$link}" class="list-group-item">{
        <div class="result-entry">
            <h4 class="list-group-item-heading result-entry-title">{$title}{$images}{$transcripts}</h4>
            <p class="list-group-item-text result-entry-author">{$author}</p>
            <p class="list-group-item-text result-entry-snippet">{$snippet//p/child::*}</p>
            <p class="list-group-item-text result-entry-witness">{$witnesses}</p>
            <p class="list-group-item-text result-entry-mss"><strong>{$mss}</strong></p>
        </div>
    }</a>
};

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
 :
 : @param $item - an item from a result set.
 : @return a partal app URL for a text
 :)
declare function mpese-search:author-list($item, $include_roles as xs:boolean) {
    if ($include_roles) then
        $item//tei:fileDesc/tei:titleStmt/tei:author
    else
        $item//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
};

(:~
 : Show an icon to represent a search result has images?
 :
 : @param $item – an item from a result set
 : @return an icon or nothing
 :)
declare function mpese-search:images($item) as node()* {
    if (count($item//tei:facsimile/tei:graphic) > 0) then
        (text{' '}, <span class="glyphicon glyphicon-camera" aria-hidden="true"></span>,
        <span class="sr-only">Images available</span>)
    else ()
};

(:~
 : Show an icon to represent a search result has a transcript?
 :
 : @param $item – an item from a result set
 : @return an icon or nothing
 :)
declare function mpese-search:transcript($item) as node()* {
    if (fn:not(fn:normalize-space($item//tei:text[1]) eq '')) then
        (text{' '}, <span class="glyphicon glyphicon-file" aria-hidden="true"></span>,
        <span class="sr-only">Transcript available</span>)
    else ()
};

(:~
 : Give a witness count. Add 1 to include that text ... 0 looks weird
 :
 : @param $item – an item from a result set
 :)
declare function mpese-search:witness-count($item) as xs:string {
    let $total := fn:count($item//tei:listBibl[@xml:id='mss_witness_generated']/tei:bibl) + fn:number(1)
    return
        if ($total eq 1) then '1 witness' else $total || ' witnesses'
};

(:~
 : Create a pagination link, i.e. a link to a page in the navigation.
 :
 : @page – the page in the navigation
 : @map – map of key/value pairs that will be request parameters
 : @type – type of search ('basic', adv')
 : @return a string that represents a URL
 :)
declare function mpese-search:pagination-link($page, $map, $type) {
    let $base := if ($type eq 'adv') then './results.html?page=' else './?page='
    let $params := for $key in map:keys($map)
        return
        if ($key eq 'page') then ()
        else if ($map($key) eq '') then ()
        else ($key || '=' || fn:encode-for-uri($map($key)))
    return
        $base || $page || '&amp;' || fn:string-join($params, '&amp;')
};

(:~
 : Create a navigation bar that provides pagination for search results. The pagination will only
 : show 10 pages at a time.
 :
 : @page – the currently selected page
 : @pages - the total number of pages (but we only show 10 max)
 : @map – a map of key/value pairs used to construct a URL
 : @label – label for the pagination (used in aria-label)
 : @return a <nav/> with pagination.
 :)
declare function mpese-search:pagination($page as xs:integer, $pages as xs:integer,
    $map as map(xs:string, xs:string), $label as xs:string, $type as xs:string) as node() {

    (: max pages shown in pagination :)
    let $max_pag_pages := 10

    (: current pagination part :)
    let $current_pag_part := ceiling($page div $max_pag_pages)

    (: starting page number in pagination :)
    let $offset := $max_pag_pages - 1
    let $pag_start := xs:integer($current_pag_part * $max_pag_pages - $offset)
    let $pag_end := if (($pag_start + $offset) > $pages) then $pages else ($pag_start + $offset)

    return
    <nav id="paginaton" aria-label="{$label}">
        <div class="text-center">
            <ul class="pagination">
                {
                    if ($pages > $max_pag_pages) then
                        if ($page eq 1) then
                            <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">First</a></li>
                        else
                            <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link(1, $map, $type)}">First</a></li>
                    else ()
                }
                {
                    if ($page eq 1) then
                        <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Previous</a></li>
                    else
                        <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($page - 1, $map, $type)}">Previous</a></li>
                }
                {
                    for $count in $pag_start to $pag_end
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
                {
                    if ($pages > $max_pag_pages) then
                        if ($page eq $pages) then
                            <li class="page-item disabled"><a class="page-link" tabindex="-1" href="">Last</a></li>
                        else
                            <li class="page-item"><a class="page-link" href="{mpese-search:pagination-link($pages, $map, $type)}">Last</a></li>
                    else ()
                }
            </ul>
        </div>
     </nav>
};

(:~
 : Try and restrict KWIC results to increase performance ... TODO Revisit all this.
 :)
declare function mpese-search:matches($result) {
    let $matches := kwic:get-matches($result)
    let $matches_sub := subsequence($matches, 1, 3)
    let $kwic := for $ancestor in $matches_sub/ancestor::*
        return kwic:get-summary($ancestor, ($ancestor//exist:match, $ancestor//*[@exist:matches])[1], <config width="40"/>)
    return functx:distinct-deep($kwic)
};


(:~
 : Set cookies with values of parameters that can be used in reconstructing the URL of a search,
 : including pagination, so we can return to the search results after the end-user as
 : navigated to a text and beyond!
 :
 : @type the type of meeting ('adv','basic'), since they have a different URL for the results
 : @param a map of the key/value pairs that can construct a search URL
 : @return set a cookie
 :)
declare function mpese-search:cookies($type as xs:string, $map as map(xs:string, xs:string)) as item()? {
    utils:reset-cookies(),
    response:set-cookie('mpese-search-type', $type),
    for $key in map:keys($map)
        return response:set-cookie('mpese-search-' || $key, util:base64-encode(($map($key))))
};

(:~
 : A function to dislay a page of results. The function sets a cookie to keep track of the original
 : query and what page was selected in the navigation. A <results/> in-memory documents is passed
 : in which includes the results we want to display on the page - this is a subset of the complete
 : resultset and the calling function creates this subset. This function then queries the documents
 : of interest to pull out additional information which is needed in the results page.
 :
 : @param $page – the current pages number in the pagination
 : @param $order – type of results ordering
 : @param $total – total number of results
 : @param $results – the results to display (possibly a subset of all)
 : @return a <div/> with the search results for rendering in the browser
 :)
declare function mpese-search:render-results($page as xs:integer, $type as xs:string, $pages as xs:integer,
                                             $total as xs:integer, $results as node(),
                                             $map as map(xs:string, xs:string)) as node()* {

    let $message := mpese-search:results-message($total)
    return
    (mpese-search:cookies($type, $map),
    <div id="search-results">
        {
            if ($type eq 'adv') then <p class="text-center results-total">{$message, text{" "}}
                <a href="{mpese-search:results-edit-search-link($map)}">Edit search</a>.</p>
            else <p class="text-center results-total">{$message}</p>
        }
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $map, "Top navigation", $type)
            else
                ""
        }
        <div class="list-group">{

            for $result in $results/result
                let $uri := $result/@uri/fn:string()
                let $item := doc($uri)/tei:TEI
                    return if (not($item)) then () else
                        let $title := mpese-text:title-label($item)
                        let $authors := $item//tei:fileDesc/tei:titleStmt/tei:author[not(@role)]
                        let $mss := mpese-text:mss-details($item)
                        let $mss-label := mpese-mss:ident-label($mss)
                        let $author-label := mpese-text:author-label($authors)
                        let $link := mpese-search:text-link($item)
                        let $snippet := $result/summary
                        let $images := mpese-search:images($item)
                        let $transcripts := mpese-search:transcript($item)
                        let $witnesses := mpese-search:witness-count($item)
                        return mpese-search:result-entry($link, $title, $author-label, $snippet, $mss-label, $images,
                                                         $transcripts, $witnesses)
        }
        </div>
        {
            if ($pages > 1) then
                mpese-search:pagination($page, $pages, $map, "Bottom navigation", $type)
            else
                ""
        }
    </div>)
};

(:~
 : Get all texts from the corpus. This is the default method called when no query term has been set.
 : After getting the results we create a subset of the results based on which page of results was
 : requested to be displayed.
 :
 : @param $page – the selected page in the navigation
 : @param $num – the number of results to display per page.
 :)
declare function mpese-search:all($page as xs:integer, $num as xs:integer) as node()*  {

    (: type of search :)
    let $type := 'basic'

    (: get details of all of the texts :)
    let $results := mpese-search:all()

    (: total hits :)
    let $total := fn:count($results/result)

    (: starting point for the subset :)
    let $start := mpese-search:seq-start($page, $num)

    (: total number of pages :)
    let $pages := mpese-search:pages-total($total, $num)

    (: subset :)
    let $results_subset := mpese-search:paginate-results($results, $start, $num)

    (: rebuild search in pagination / cookie after navigating :)
    let $map := map { 'page' := $page }

    (: render the subset :)
    return
        mpese-search:render-results($page, $type, $pages, $total, $results_subset, $map)
};

(:~
 : Process a search against the corpus. After getting the results we create a subset of the results based
 : on which page of results was requested to be displayed.
 :
 : @param $type – type of search ('basic' or 'adv')
 : @param $page – the selected page in the navigation
 : @param $num – the number of results to display per page
 : @param $search – the search string
 : @param $keyword-type – type of search on keyword, e.g. 'all'
 : @param $exclude – keywords to exclude
 : @param $start-range – start date range
 : @param $end-date – end date range
 : @param $order-by – order by date  ...
 : @return search results
 :)
declare function mpese-search:process-search($type as xs:string, $page as xs:integer, $num as xs:integer,
                                             $search as xs:string, $keyword-type as xs:string, $exclude as xs:string,
                                             $image as xs:string, $transcript as xs:string,
                                             $start-range as xs:string, $end-range as xs:string,
                                             $order-by as xs:string) as node() {

    let $search_m := if ($type eq 'basic') then mpese-search:process-simple-search($search) else $search

    (: all results, unpaginated :)
    let $results := mpese-search:advanced($search_m, $keyword-type, $exclude, $image, $transcript, $start-range, $end-range, $order-by)

    (: total hits :)
    let $total := fn:count($results/result)

    (: starting point for the subset :)
    let $start := mpese-search:seq-start($page, $num)

    (: total number of pages :)
    let $pages := mpese-search:pages-total($total, $num)

    (: subset :)
    let $results-subset := mpese-search:paginate-results($results, $start, $num)

    (: rebuild search in pagination :)
    let $map := map { 'search' := $search, 'keyword-type' := $keyword-type, 'exclude' := $exclude, 'start-range' := $start-range,
                      'end-range' := $end-range, 'image' := $image, 'transcript' := $transcript,
                      'order-by' := $order-by, 'page' := $page }

    return mpese-search:render-results($page, $type, $pages, $total, $results-subset, $map)
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



(: ---------- TEMPLATE FUNCTIONS ----------- :)

declare %templates:default("search", "") %templates:default("order-by", "relevance")function mpese-search:form($node as node (), $model as map (*),
        $search as xs:string, $order-by as xs:string)  {

    let $rel_order := if ($order-by eq 'relevance') then
            <input name="order-by" value="relevance" type="radio" checked="checked"/>
        else
            <input name="order-by" value="relevance" type="radio"/>

    let $date_order := if ($order-by eq 'date_a') then
            <input name="order-by" value="date_a" type="radio" checked="checked"/>
        else
            <input name="order-by" value="date_a" type="radio"/>
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
declare %templates:default("page", 1)
%templates:default("num", 20)
%templates:default("search", "")
%templates:default("order-by", "relevance")
function mpese-search:default($node as node (), $model as map (*), $page as xs:integer, $num as xs:integer,
                              $search as xs:string, $order-by as xs:string)  {
    util:log('INFO', 'basic search ...'),
    mpese-search:process-search('basic', $page, $num, $search, 'any', '', '', '', '', '', $order-by)
};

declare function mpese-search:last-change($node as node (), $model as map (*))  {
    let $date := doc('/db/mpese/tei/corpus/meta/mpese.xml')//tei:text/tei:body/tei:div[1]/tei:head/tei:date/string()
    return
        <div class="alert alert-info text-center"><a href="./changes.html">Last updated on {$date}. See changes.</a></div>
};


declare
%templates:default("search", "")
%templates:default("keyword-type", "any")
%templates:default("exclude", "")
%templates:default("start-range", "")
%templates:default("end-range", "")
%templates:default("image", "no")
%templates:default("transcript", "no")
%templates:default("order-by", 'date_a')
function mpese-search:advanced-form($node as node (), $model as map (*),
        $search as xs:string, $keyword-type as xs:string, $exclude as xs:string, $start-range as xs:string,
        $end-range as xs:string, $image as xs:string, $transcript as xs:string, $order-by as xs:string)  {

    let $input_any := if ($keyword-type eq 'any') then <input type="radio" name="keyword-type" id="adv_search_type1" value="any" checked="checked"/>
                      else <input type="radio" name="keyword-type" id="adv_search_type1" value="any"/>

    let $input_all := if ($keyword-type eq 'all') then <input type="radio" name="keyword-type" id="adv_search_type2" value="all" checked="checked"/>
                      else <input type="radio" name="keyword-type" id="adv_search_type2" value="all"/>

    let $input_phrase := if ($keyword-type eq 'phrase') then <input type="radio" name="keyword-type" id="adv_search_type3" value="phrase" checked="checked"/>
                         else <input type="radio" name="keyword-type" id="adv_search_type3" value="phrase"/>

    let $text_with_images := if ($image eq 'yes') then <input type="checkbox" name="image" id="adv_image_only" value="yes" checked="checked"/>
                             else <input type="checkbox" name="image" id="adv_image_only" value="yes"/>

    let $text_with_transcript := if ($transcript eq 'yes') then <input type="checkbox" name="transcript" id="adv_transcript_only" value="yes" checked="checked"/>
                             else <input type="checkbox" name="transcript" id="adv_transcript_only" value="yes"/>

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
                <label class="checkbox-inline">
                    {$text_with_transcript} show only texts with a transcript
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
%templates:default("num", 20)
%templates:default("search", "")
%templates:default("keyword-type", "any")
%templates:default("exclude", "")
%templates:default("start-range", "")
%templates:default("end-range", "")
%templates:default("image", "no")
%templates:default("transcript", "no")
%templates:default("order-by", 'date_a')
function mpese-search:advanced-results($node as node (), $model as map (*), $page as xs:integer, $num as xs:integer,
                                       $search as xs:string, $keyword-type as xs:string, $exclude as xs:string,
                                       $start-range as xs:string, $end-range as xs:string, $image as xs:string,
                                       $transcript as xs:string, $order-by as xs:string)  {

    mpese-search:process-search('adv', $page, $num, $search, $keyword-type, $exclude, $image, $transcript, $start-range,
                                $end-range, $order-by)
};