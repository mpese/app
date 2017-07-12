xquery version "3.1";

(:~
: A module with functions that are useful in the dashboard.
:
: @author Mike Jones (mike.a.jones@bristol.ac.uk)
:)
module namespace dashboard = "http://mpese.rit.bris.ac.uk/dashboard/";

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace ui = "http://mpese.rit.bris.ac.uk/ui/" at "ui.xql";

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
            let $store := xmldb:store($config:word_docs, encode-for-uri($filename),
                    request:get-uploaded-file-data($param_name))
            return
                if (not($store)) then
                    ui:alert-fail(fn:concat($filename, ' has not been been stored!'), $redirect)
                else
                    ui:alert-success(fn:concat($filename, ' has been stored'), $redirect)

};


declare function dashboard:unzip($docx as xs:string) {

};

declare function dashboard:list_word_docs($node as node(), $model as map(*)) {

    let $list := xmldb:get-child-resources($config:word_docs)

    for $doc in $list
    return
        <p>{xmldb:decode-uri($doc)}</p>

};
