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
import module namespace mpese-text = "http://mpese.rit.bris.ac.uk/corpus/text/" at '../modules/mpese-corpus-text.xqm';
import module namespace mpese-mss = "http://mpese.rit.bris.ac.uk/corpus/mss/" at '../modules/mpese-corpus-mss.xqm';

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

(: helper function for listing keywords :)
declare function dashboard:keywords_as_list($att) {
    let $keywords := collection('/db/mpese/tei/corpus/')//tei:keywords[@n=$att]/tei:term
    return
    <ul class='list-inline'>{
        for $keyword in fn:distinct-values($keywords)
        order by $keyword ascending
            return
                if(not(functx:all-whitespace($keyword))) then
                    <li><a href="{concat('./index.html?', $att, '=', $keyword)}">{$keyword}</a></li>
                else
                    ()
    }</ul>
};


declare function dashboard:authors($authors) {
    if (fn:count($authors) eq 1) then
            $authors/text()
        else
            for $author in $authors
            return
                if (not($author eq functx:last-node($authors))) then
                    concat($author/text(), '; ')
                else
                    concat(' and ', $author)
};

declare function dashboard:get-texts($text-type, $topic-keyword, $missing) {

    if ($text-type) then
        fn:collection($config:mpese-tei-corpus-texts)//tei:keywords[@n="text-type"]/tei:term[text() eq $text-type]
    else if ($topic-keyword) then
        fn:collection($config:mpese-tei-corpus-texts)//tei:keywords[@n="topic-keyword"]/tei:term[text() eq $topic-keyword]
    else if ($missing) then
        if ($missing eq 'bibliography') then
            dashboard:missing-bibliography()
        else
            fn:collection($config:mpese-tei-corpus-texts)
    else
        fn:collection($config:mpese-tei-corpus-texts)
};

(: get the last-modified date of the node's document, i.e. TEI document :)
declare function dashboard:last-modified($doc_name) {
            let $lmd := xmldb:last-modified($config:mpese-tei-corpus-texts, $doc_name)
            return
                fn:format-dateTime($lmd, $config:date-time-fmt)
};

(: get the documents that are missing a bibliography; checks for a bibl with no content or an xml
 : comment, as found in templates used by the researchers :)
declare function dashboard:missing-bibliography() as node()* {
    for $bibl in fn:collection($config:mpese-tei-corpus-texts)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listBibl/tei:bibl
    where not($bibl/node()) or $bibl/comment()
    return $bibl
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
                        let $uri := fn:concat('text/', $name, '/index.html')
                        return
                            if(not(functx:all-whitespace($title))) then
                                <a href="{$uri}">{$title}</a>
                            else
                                <a href="{$uri}">{string('Untitled')}</a>
                    }</td>
                    <td>{$tei/tei:TEI/tei:teiHeader/tei:profileDesc/tei:creation/tei:date/text()}</td>
                    <td>{
                        let $authors:= $tei/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author
                        return dashboard:authors($authors)
                    }</td>
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

    let $text-type := request:get-parameter('text-type', '')
    let $topic-keyword := request:get-parameter('topic-keyword', '')
    let $missing-data := request:get-parameter('missing', '')

    let $texts := dashboard:get-texts($text-type, $topic-keyword, $missing-data)
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
    fn:count(fn:distinct-values(dashboard:missing-bibliography()))
};
