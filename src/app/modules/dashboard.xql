xquery version "3.1";

(:~
: A module with functions that are useful in the dashboard.
:
: @author Mike Jones (mike.a.jones@bristol.ac.uk)
:)
module namespace dashboard = "http://mpese.rit.bris.ac.uk/dashboard/";

declare namespace w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
declare namespace tei = 'xmlns="http://www.tei-c.org/ns/1.0';

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace ui = "http://mpese.rit.bris.ac.uk/ui/" at "ui.xql";
import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/" at '../modules/utils.xql';

declare function dashboard:process_word_xml($path as xs:string) {

    let $doc := doc($path)
        return
            <body> {
                for $p in $doc//w:p
                return
                    <p>{
                        for $wr in $p/w:r
                        return
                            $wr/w:t/text()
                    }</p>
            }</body>
};

declare function dashboard:tei_template($insert) {
    let $template := doc(concat($config:app-root, '/modules/mpese_text_template.xml'))
        return
            update insert ($insert) into $template/tei:body

};

(:~
 : Processes a .docx file upload and stores it in database. The function adds an
 : an appropriate message to the session so it can be displayed in the UI.
 :
 : @param $param_name - the parameter name that references the file.
 : @param $redirect - where we want to go after the operation.
 : @return a HTTP redirect with a message added to the sesssion.
 : @author Mike Jones (mike.a.jones@bristol.ac.uk)
:)
declare function dashboard:store_word_doc($param_name as xs:string, $redirect as xs:anyURI) {

    let $filename := request:get-uploaded-file-name($param_name)

    return
    (: check a filename is set :)
        if ($filename eq '') then
            ui:alert-fail('No file provided', $redirect)
        (: bail if it isn't a .docx file :)
        else if (not(fn:ends-with($filename, '.docx'))) then
            ui:alert-fail('No a .docx file', $redirect)
        else
        (: attempt to store the file :)
            let $data := request:get-uploaded-file-data($param_name)
            let $store := xmldb:store($config:word_docs, encode-for-uri($filename), $data)
            return
                if (not($store)) then
                    ui:alert-fail(fn:concat($filename, ' has not been been stored!'), $redirect)
                else
                (: TODO, unzip and process ? :)
                    (:(utils:unzip('/db/word_docs_xml/', functx:substring-after-last($store, '/'), 'unzip'),:)
                        (:ui:alert-success(fn:concat($filename, ' has been stored'), $redirect)):)
                        let $result := utils:unzip('/db/word_docs_xml/', functx:substring-after-last($store, '/'), 'unzip')
                            return
                                let $word_xml_path := $result/result[@object='word/document.xml']/@destination
                                let $xsl_path := concat($config:app-root, '/modules/word_to_tei.xsl')
                                let $xml := doc($word_xml_path)
                                let $insert := dashboard:process_word_xml($word_xml_path)
                                (:return $insert:)
                                return dashboard:tei_template($insert)

};

declare function dashboard:list_word_docs($node as node(), $model as map(*)) {

    let $list := xmldb:get-child-resources($config:word_docs)

    for $doc in $list
    return
        <p>{xmldb:decode-uri($doc)}</p>

};
