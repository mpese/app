xquery version "3.1";

(:~
: A module with functions that are useful in the dashboard.
:
: @author Mike Jones (mike.a.jones@bristol.ac.uk)
:)
module namespace dashboard = "http://mpese.rit.bris.ac.uk/dashboard/";

declare namespace w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace util = "http://exist-db.org/xquery/util";
import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace ui = "http://mpese.rit.bris.ac.uk/ui/" at "ui.xql";
import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/" at '../modules/utils.xql';
import module namespace mpese-text = "http://mpese.rit.bris.ac.uk/corpus/text/" at 'mpese-corpus-text.xqm';
import module namespace mpese-mss = "http://mpese.rit.bris.ac.uk/corpus/mss/" at 'mpese-corpus-mss.xqm';
import module namespace mpese-person = "http://mpese.rit.bris.ac.uk/corpus/person/" at 'mpese-corpus-person.xqm';

declare function dashboard:process_word_xml($path as xs:string) {

    let $doc := doc($path)
    return
        <body xmlns="http://www.tei-c.org/ns/1.0"> {
            for $p in $doc//w:p
            return
                <p>{
                    for $wr in $p/w:r
                    return
                        $wr/w:t/text()
                }</p>
        }</body>
};

(:~
 : Replace the TEI:body with a new body, i.e. insert into our template
 : the content we have extracted from Word.
 :
 : @param $doc - a copy of our template.
 : @param $body - a replacement TEI:body.
:)
declare function dashboard:insert_tei($doc, $body) {
    update replace doc($doc)//tei:body with $body
};

(:~
 : Store a copy of our template in the database and replace the TEI:body
 : with a new body, i.e. insert into our template the content we have
 : extracted from Word.
 :
 : @param $doc - a copy of our template.
 : @param $body - a replacement TEI:body.
 : @returns the location of the new XML file.
:)
declare function dashboard:tei_template($filename, $body) {

    (: create a new file based on the template :)
    let $template := doc($config:tei-template)
    let $doc := xmldb:store($config:mpese-tei-corpus-texts, fn:encode-for-uri($filename), $template)

    (: insert the new TEI body into the new file :)
    let $insert := dashboard:insert_tei($doc, $body)

    return $doc
};


(:~
 : Processes a .docx file upload and stores it in database. The function adds an
 : an appropriate message to the session so it can be displayed in the UI.
 :
 : @param $param_name - the parameter name that references the file.
 : @param $redirect - where we want to go after the operation.
 : @return a HTTP redirect with a message added to the sesssion.
:)
declare function dashboard:store_word_doc($param_name as xs:string) {

    let $filename := request:get-uploaded-file-name($param_name)

    return
    (: check a filename is set :)
    if ($filename eq '') then
        <message type="warn">No file provided</message>
    (: bail if it isn't a .docx file :)
    else if (not(fn:ends-with($filename, '.docx'))) then
        <message type="warn">No a .docx file</message>
    else
        (: attempt to store the file :)
        let $data := request:get-uploaded-file-data($param_name)
        let $store := xmldb:store($config:mpese-word-docx, encode-for-uri($filename), $data)
        return
            if (not($store)) then
                <message type="warn">fn:concat($filename, ' has not been been stored!')</message>
            else
                (: unzip the file :)
                let $result := utils:unzip(concat($config:mpese-word-unzip, '/'), functx:substring-after-last($store, '/'), 'unzip')
                (: find and process the document.xml file :)
                let $word_xml_path := $result/result[@object = 'word/document.xml']/@destination
                let $xml := doc($word_xml_path)
                let $data := dashboard:process_word_xml($word_xml_path)
                (: store the processed content within a copy of our template :)
                let $xml_filename := fn:concat(substring-before($filename, '.docx'), '.xml')
                let $template := dashboard:tei_template($xml_filename, $data)
                (: delete the word doc :)
                let $remove_word := xmldb:remove($config:mpese-word-docx, encode-for-uri($filename))
                (: delete the unzipped .docx :)
                let $remove_zip := xmldb:remove(fn:concat($config:mpese-word-unzip, '/',
                        fn:encode-for-uri(substring-before($filename, '.docx')),'_docx_parts'))
                return
                    <message type="success">{fn:concat($filename, ' has been processed')}</message>
};



declare function dashboard:empty-element($element as element()) {
    not($element/node()) or $element/comment()
};

(: find documents that have mission bibliographical detail :)
declare function dashboard:missing-biblio() {
    let $missing-biblio := (
        for $a in  fn:collection($config:mpese-tei-corpus-texts)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listBibl/tei:bibl
        where dashboard:empty-element($a)
        return document-uri(root($a)))
    let $distinct-missing := distinct-values($missing-biblio)
    return
        for $a in $distinct-missing
        order by doc($a)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
            return doc($a)

};



(: helper function for listing keywords :)
declare function dashboard:keywords_as_list($att) {
    let $keywords := collection('/db/mpese/tei/corpus/')//tei:keywords[@n=$att]/tei:term
    let $code := ( if ($att eq 'text-type') then '01' else '02')
    return
    <ul class='list-inline'>{
        for $keyword in fn:distinct-values($keywords)
        order by $keyword ascending
            return
                if(not(functx:all-whitespace($keyword))) then
                    <li><a href="{concat('./index.html?code=', $code, '&amp;value=', $keyword)}">{$keyword}</a></li>
                else
                    ()
    }</ul>
};


declare function dashboard:authors($authors) {

    if (fn:count($authors) eq 1) then
            $authors/string()
        else
            for $author in $authors
            return
                if (not($author eq functx:last-node($authors))) then
                    concat($author/string(), '; ')
                else
                    concat(' and ', $author)
};

(:
 :  Filters
 :
 :  01 - matching a specific text-type
 :  02 - matching a specific topic-keyword
 :  03 - missing a bibliography
 :  04 – unclear text
 :  05 - dates that haven't been normalised
 :)

declare function dashboard:get-texts($code, $value) {

    if ($code eq '01') then
        fn:collection($config:mpese-tei-corpus-texts)//tei:keywords[@n="text-type"]/tei:term[text() eq $value]
    else if ($code eq '02') then
        fn:collection($config:mpese-tei-corpus-texts)//tei:keywords[@n="topic-keyword"]/tei:term[text() eq $value]
    else if ($code eq '03') then
        dashboard:missing-biblio()
    else if ($code eq '04') then
        dashboard:unclear-used()
    else if ($code eq '05') then
        dashboard:not-normalized-dates()
    else
        dashboard:search-texts('')
};

declare function dashboard:search-texts($phrase) {

    let $search_phrase := (if ($phrase eq '') then '*:*' else $phrase)
    let $matches := fn:collection($config:mpese-tei-corpus-texts)//tei:titleStmt/tei:title[ft:query(., $search_phrase)] |
        fn:collection($config:mpese-tei-corpus-texts)//tei:titleStmt/tei:author[ft:query(., $search_phrase)]
    let $docs := ( for $a in $matches return document-uri(root($a)))
    let $distinct := fn:distinct-values($docs)
    return
        for $a in $distinct
        order by doc($a)//tei:titleStmt/tei:title
            return doc($a)
};

(: get the last-modified date of the node's document, i.e. TEI document :)
declare function dashboard:last-modified($doc_name) {
            let $lmd := xmldb:last-modified($config:mpese-tei-corpus-texts, $doc_name)
            return
                fn:format-dateTime($lmd, $config:date-time-fmt)
};


declare function dashboard:unclear-used() {
    let $missing-biblio := (
        for $a in fn:collection($config:mpese-tei-corpus-texts)//tei:unclear
        return document-uri(root($a)))
    let $distinct-missing := distinct-values($missing-biblio)
    return
        for $a in $distinct-missing
        order by doc($a)//tei:titleStmt/tei:title
            return doc($a)
};

declare function dashboard:not-normalized-dates() {
    let $dates := (
        for $a in fn:collection($config:mpese-tei-corpus-texts)//tei:date[not(@when)]
        return document-uri(root($a)))
    let $distinct-missing := distinct-values($dates)
    return
        for $a in $distinct-missing
        order by doc($a)//tei:titleStmt/tei:title
            return doc($a)
};



declare function dashboard:texts_table($texts) {
    <div>
        <p class='mpese-text-count'>{fn:count($texts)} results.</p>
        <table id="mpese-dash-texts" class="table table-responsive table-striped">
            <thead>
                <tr>
                    <th>Title</th>
                    <th>Author</th>
                    <th>Date</th>
                    <th>Last Modified</th>
                </tr>
            </thead>
            <tbody>{
            for $a in $texts
            let $tei := root($a)
            (: extract the filename from the full path :)
            let $doc_name := functx:substring-after-last(fn:document-uri($tei), '/')
            return
                <tr>
                    <td>{
                        let $title := $tei/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
                        let $name := fn:substring-before($doc_name, '.xml')
                        let $uri := fn:concat('text/', $name, '.html')
                        return
                            if(not(functx:all-whitespace($title))) then
                                <a href="{$uri}">{$title}</a>
                            else
                                <a href="{$uri}">{string('Untitled')}</a>
                    }</td>
                    <td>{
                        let $authors:= $tei/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author

                        return
                            (util:log('INFO', (document-uri(root($tei)))),
                            dashboard:authors($authors))
                    }</td>
                    <td>{$tei/tei:TEI/tei:teiHeader/tei:profileDesc/tei:creation/tei:date/text()}</td>
                    <td>{dashboard:last-modified($doc_name)}</td>
                </tr>
            }</tbody>
        </table>





    </div>
};


(: --------- TEMPLATE FUNCTIONS --------- :)

(: TODO - add a title to the TEI/XML document :)
(: TODO - list the TEI/XML rather than Word docs :)

declare function dashboard:list_texts($node as node (), $model as map (*)) {

    if (functx:is-value-in-sequence('search', request:get-parameter-names())) then
        let $search := request:get-parameter('search', '')
        return
            dashboard:texts_table(dashboard:search-texts($search))
    else

        let $code := request:get-parameter('code', '')
        let $value := request:get-parameter('value', '')

        let $texts := dashboard:get-texts($code, $value)
            return
            dashboard:texts_table($texts)
};

(: count the numbers of texts :)
declare function dashboard:count_texts($node as node (), $model as map (*)) {
    let $list := xmldb:get-child-resources($config:mpese-tei-corpus-texts)
    return count($list)
};

(: count the number of manuscripst :)
declare function dashboard:count_mss($node as node (), $model as map (*)) {
    let $list := xmldb:get-child-resources($config:mpese-tei-corpus-mss)
    return count($list)
};

(: count the number of people :)
declare function dashboard:count_people($node as node (), $model as map (*)) {
    let $people := collection($config:mpese-tei-corpus-people)//tei:person
    return fn:count($people)
};

(: list the @rend attribute values :)
declare function dashboard:rend_atts($node as node (), $model as map (*)) {
    let $attrs := collection($config:mpese-tei-corpus)//@rend
    return
    <ul class='list-inline'>{
        for $att in fn:distinct-values($attrs)
        order by $att ascending
            return
            <li>{$att}</li>
    }</ul>
};

(: list the text type keywords :)
declare function dashboard:text_types($node as node (), $model as map (*)) {
    dashboard:keywords_as_list('text-type')
};

(: list the topic keywords :)
declare function dashboard:topic_keywords($node as node (), $model as map (*)) {
    dashboard:keywords_as_list('topic-keyword')
};

declare function dashboard:total_missing_bibliographies($node as node (), $model as map (*)) {
    fn:count(dashboard:missing-biblio())
};

declare function dashboard:total_missing_unclear($node as node (), $model as map (*)) {
    fn:count(dashboard:unclear-used())
};

declare function dashboard:total_not_normalized_dates($node as node (), $model as map (*)) {
    fn:count(dashboard:not-normalized-dates())
};

declare function dashboard:text-download-xml($node as node (), $model as map (*)) {
    let $file := request:get-attribute('text')
    return
        <p><a href="./{$file}" download="{$file}">Download XML</a></p>
};

declare function dashboard:total-person($node as node (), $model as map (*)) {
    mpese-person:total-count()
};

declare function dashboard:mss-download-xml($node as node (), $model as map (*)) {
    let $file := request:get-attribute('mss')
    return
        <p><a href="./{$file}" download="{$file}">Download XML</a></p>
};
