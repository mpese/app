xquery version "3.1";


declare namespace json="http://www.json.org";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

declare option exist:serialize "method=json media-type=text/javascript";

import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';


let $file := request:get-parameter('file','')

return
    <response>{
    if(empty($file) or $file eq '') then
        (response:set-status-code(400),
        <error>Bad request: no filename</error>)
    else if (not(doc-avalable($config:mpese-tei-corpus-texts || '/' || $id || ".xml")))
        (response:set-status-code(404),
        <error>Bad request: document not found</error>)
    else
        (: get the document :)
        let $doc := doc($config:mpese-tei-corpus-texts || '/' || $file || ".xml")

        (: get results :)
        let $results :=
            if (doc-available($doc)) then
                for $image in doc($doc)//tei:facsimile/tei:graphic
                order by xs:int($image/@n)
                return <images json:array="true">{$image/@url/string()}</images>
            else
                <images json:array="true"/>
        return
        (response:set-status-code(200),
        <results>{$results}</results>
        )
    }</response>