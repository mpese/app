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

(: TODO - add a title to the TEI/XML document :)
(: TODO - list the TEI/XML rather than Word docs :)

declare function dashboard:list_word_docs($node as node (), $model as map (*)) {

    let $list := xmldb:get-child-resources($config:mpese-tei-corpus-texts)
    return
    <table class="table table-striped">
        <thead>
            <th>File</th>
            <th>Path</th>
        </thead>
        <tbody>{
        for $tei in $list
            return
            <tr>
                <td>{xmldb:decode-uri($tei)}</td>
                <td>{fn:concat($config:mpese-tei, '/', $tei)}</td>
            </tr>
        }</tbody>
    </table>
};
