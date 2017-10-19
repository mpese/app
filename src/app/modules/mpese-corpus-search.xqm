xquery version "3.1";

module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/' at 'mpese-corpus-text';
import module namespace functx = 'http://www.functx.com' at 'functx-1.0.xql';


declare function mpese-search:result-title($doc) {
    let $tmp_title := $doc//tei:fileDesc/tei:titleStmt/tei:title/string()
    let $tmp_date := $doc//tei:profileDesc/tei:creation/tei:date[1]/string()
    let $title := ( if (fn:string-length($tmp_title) > 0) then $tmp_title else fn:string('Untitled') )
    let $date  := ( if (fn:string-length($tmp_date) > 0) then $tmp_date else fn:string('No date') )
    return
        concat($title, ', ', $date, ')')

};

declare function mpese-search:default-title() {

    let $search_phrase := '*:*'
    let $results := fn:collection($config:mpese-tei-corpus-texts)//tei:titleStmt/tei:title[ft:query(., $search_phrase)]
    return
        $results
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


(: ---------- TEMPLATE FUNCTIONS ----------- :)


(: default search, i.e. no search results defined  :)
declare function mpese-search:default($node as node (), $model as map (*))  {
    <div class="list-group" id="search-results">{
        let $results := mpese-search:default-title()
        for $item in $results
            let $uri := fn:base-uri($item)
            let $doc := doc($uri)
            let $title := mpese-search:result-title($doc)
            let $authors := mpese-text:authors($uri)
            let $mss := mpese-text:mss-details($uri)
            let $mss-label := ( if (fn:string-length($mss/string()) > 0) then
                                    concat($mss/tei:repository/string(), ', ', $mss/tei:collection/string(), ', ',
                                            $mss/tei:idno/string()) else '')
            let $author-label := mpese-search:author-label($authors)
            let $text := doc($uri)//tei:text[1]/tei:body/tei:p[1]/string()
            return <a href="#" class="list-group-item">{
                <div class="result-entry">
                    <h4 class="list-group-item-heading result-entry-title">{$title}</h4>
                    <p class="list-group-item-text result-entry-author">{$author-label}</p>
                    <p class="list-group-item-text result-entry-snippet"><em>{fn:substring($text, 1, 200)} ...</em></p>
                    <p class="list-group-item-text result-entry-mss"><strong>{$mss-label}</strong></p>
                </div>
            }</a>
    }
    </div>
};