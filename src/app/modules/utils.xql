xquery version "3.0";

(:~
: A module with useful functions for the MPESE app.
:
: @author Mike Jones (mike.a.jones@bristol.ac.uk)
:)

module namespace utils = "http://mpese.rit.bris.ac.uk/utils/";

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace functx = "http://www.functx.com" at "functx-1.0.xql";

(:~
 : A function needed by compression:unzip which filters resources when unzipping.
 : We are not doing any filtering here.
 :
 : @param $path - a path!
 : @param $type -.a 'resource' or a 'folder'
 : @param $param - a sequence with additional parameters.
 : @return true() for everything, i.e. no filtering
 : @see http://exist-db.org/xquery/compression
 : @see https://en.wikibooks.org/wiki/XQuery/Get_zipped_XML_file
 : @see https://en.wikibooks.org/wiki/XQuery/Unzipping_an_Office_Open_XML_docx_file
:)
declare function utils:zip-filter($path as xs:string, $type as xs:string, $param as item()*) as xs:boolean {
    (: pass all :)
    true()
};

(:~
 : A function needed by compression:unzip for storing extracted resources from a zipped file.
 :
 : @param $path - a path!
 : @param $data-type - a 'resource' or a 'folder'.
 : @param $data -.data to be stored
 : @return the stored location
 : @see http://exist-db.org/xquery/compression
 : @see https://en.wikibooks.org/wiki/XQuery/Get_zipped_XML_file
 : @see https://en.wikibooks.org/wiki/XQuery/Unzipping_an_Office_Open_XML_docx_file
:)
declare function utils:unzip-docx($path as xs:string, $data-type as xs:string, $data as item()?, $param as item()*) {
    if ($param[@name eq 'list']/@value eq 'true') then
        <item
            path="{$path}"
            data-type="{$data-type}"/>
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
        let $filename := if (contains($path, '/')) then
            functx:substring-after-last($path, '/')
        else
            $path
            (: we need to encode the filename to account for filenames with illegal characters like [Content_Types].xml :)
        let $filename := xmldb:encode($filename)
        let $target-collection := concat($base-collection, $zip-collection, $inner-collection)
        let $mkdir :=
        if (xmldb:collection-available($target-collection)) then
            ()
        else
            xmldb:create-collection($base-collection, concat($zip-collection, $inner-collection))
        let $store :=
        (: ensure mimetype is set properly for .docx rels files :)
        if (ends-with($filename, '.rels')) then
            xmldb:store($target-collection, $filename, $data, 'application/xml')
        else
            xmldb:store($target-collection, $filename, $data)
        return
            <result
                object="{$path}"
                destination="{concat($target-collection, '/', $filename)}"/>
};

(:~
 : A function that uses compression:unzip for extracting the contents of a .docs file.
 :
 : @param $base-collection
 : @param $zip-filename
 : @param $action
 : @return $param - a sequence with additional parameters.
 : @see http://exist-db.org/xquery/compression
 : @see https://en.wikibooks.org/wiki/XQuery/Get_zipped_XML_file
 : @see https://en.wikibooks.org/wiki/XQuery/Unzipping_an_Office_Open_XML_docx_file
:)
declare function utils:unzip($base-collection as xs:string, $zip-filename as xs:string, $action as xs:string) {
    if (not($action = ('list', 'unzip'))) then
        <error>Invalid action</error>
    else
        let $file := util:binary-doc(concat($config:mpese-word-docx, '/', $zip-filename))
        let $entry-filter := util:function(QName("http://mpese.rit.bris.ac.uk/utils/", "utils:zip-filter"), 3)
        let $entry-filter-params := ()
        let $entry-data := util:function(QName("http://mpese.rit.bris.ac.uk/utils/", "utils:unzip-docx"), 4)
        let $entry-data-params :=
        (
        if ($action eq 'list') then
            <param
                name="list"
                value="true"/>
        else
            (),
        <param
            name="base-collection"
            value="{$base-collection}"/>,
        <param
            name="zip-filename"
            value="{$zip-filename}"/>
        )
        
        (: recursion :)
        let $unzip := compression:unzip($file, $entry-filter, $entry-filter-params, $entry-data, $entry-data-params)
        return
            <results
                action="{$action}">{$unzip}</results>
};


declare function utils:name-from-uri($uri as xs:string) as xs:string  {
    let $seq1 := fn:tokenize($uri, '/')
    let $file := $seq1[fn:last()]
    let $seq2 := fn:tokenize($file, '\.')
    return $seq2[1]
};

declare function utils:reset-cookies() {
    for $cookie in request:get-cookie-names()
        return
            if (fn:starts-with($cookie, 'mpese-')) then
                response:set-cookie($cookie, '')
            else
                ()
};

(:~
 : We use cookies to keep track of searches, so we can have some basic navigation. We reconstruct
 : the parameters used in the search.
 :
 : @base-uri   the base URI to prepend the
 :)
declare function utils:search-nav($base-uri) as element()? {

    let $search-type := request:get-cookie-value('mpese-search-type')
    let $url := if ($search-type eq 'basic') then $base-uri || '?' else $base-uri || 'results.html?'

    let $params := for $cookie in request:get-cookie-names()
                        return
                            if (fn:starts-with($cookie, 'mpese-') and fn:not($cookie eq 'mpese-search-type')) then
                                let $value := request:get-cookie-value($cookie)
                                    return
                                        if (fn:not($value eq '')) then
                                            fn:substring-after($cookie, 'mpese-search-') || '=' || encode-for-uri(util:base64-decode($value))
                                        else ()
                            else ()
    return <p class="mpese-search-nav"><a href="{$url}{string-join($params, '&amp;')}">Back to search results</a></p>
};