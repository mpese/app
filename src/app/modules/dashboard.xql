xquery version "3.1";

(:~
: A module with functions that are useful in the dashboard.
:
: @author Mike Jones (mike.a.jones@bristol.ac.uk)
:)
module namespace dashboard = "http://mpese.rit.bris.ac.uk/dashboard/";

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace ui = "http://mpese.rit.bris.ac.uk/ui/" at "ui.xql";
import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";

declare function dashboard:zip-filter($path as xs:string, $type as xs:string, $param as item()*) as xs:boolean {
(: pass all :)
    true()
};


declare function dashboard:unzip-docx($path as xs:string, $data-type as xs:string, $data as item()?, $param as item()*) {
    if ($param[@name eq 'list']/@value eq 'true') then
        <item path="{$path}" data-type="{$data-type}"/>
    else
        let $base-collection := $param[@name = "base-collection"]/@value/string()
        let $zip-collection :=
            concat(
                    functx:substring-before-last($param[@name = "zip-filename"]/@value, '.'),
                    '_',
                    functx:substring-after-last($param[@name = "zip-filename"]/@value, '.')
                    ,
                    '_parts/'
            )
        let $inner-collection := functx:substring-before-last($path, '/')
        let $filename := if (contains($path, '/')) then functx:substring-after-last($path, '/') else $path
        (: we need to encode the filename to account for filenames with illegal characters like [Content_Types].xml :)
        let $filename := xmldb:encode($filename)
        let $target-collection := concat($base-collection, $zip-collection, $inner-collection)
        let $mkdir :=
            if (xmldb:collection-available($target-collection)) then ()
            else xmldb:create-collection($base-collection, concat($zip-collection, $inner-collection))
        let $store :=
            (: ensure mimetype is set properly for .docx rels files :)
            if (ends-with($filename, '.rels')) then
                xmldb:store($target-collection, $filename, $data, 'application/xml')
            else
                xmldb:store($target-collection, $filename, $data)
        return
            <result object="{$path}" destination="{concat($target-collection, '/', $filename)}"/>
};

declare function dashboard:unzip($base-collection as xs:string, $zip-filename as xs:string, $action as xs:string) {
    if (not($action = ('list', 'unzip'))) then <error>Invalid action</error>
    else
        let $file := util:binary-doc(concat($config:word_docs, $zip-filename))
        let $entry-filter := util:function(QName("http://mpese.rit.bris.ac.uk/dashboard/", "dashboard:zip-filter"), 3)
        let $entry-filter-params := ()
        let $entry-data := util:function(QName("http://mpese.rit.bris.ac.uk/dashboard/", "dashboard:unzip-docx"), 4)
        let $entry-data-params :=
            (
                if ($action eq 'list') then <param name="list" value="true"/> else (),
                <param name="base-collection" value="{$base-collection}"/>,
                <param name="zip-filename" value="{$zip-filename}"/>
            )

        (: recursion :)
        let $unzip := compression:unzip($file, $entry-filter, $entry-filter-params, $entry-data, $entry-data-params)
        return
            <results action="{$action}">{$unzip}</results>
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
                    (dashboard:unzip('/db/word_docs_xml/', functx:substring-after-last($store, '/'), 'unzip'),
                        ui:alert-success(fn:concat($filename, ' has been stored'), $redirect))

};


declare function dashboard:list_word_docs($node as node(), $model as map(*)) {

    let $list := xmldb:get-child-resources($config:word_docs)

    for $doc in $list
    return
        <p>{xmldb:decode-uri($doc)}</p>

};
