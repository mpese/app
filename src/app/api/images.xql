xquery version "3.1";

(: Return a JSON response with images for a text. Used to prime OpenSeaDragon. :)

declare namespace json="http://www.json.org";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

declare option exist:serialize "method=json media-type=text/javascript";

import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at '../modules/config.xqm';

let $type := request:get-parameter('type', 'ms')
let $id := request:get-parameter('id', '')

return
    <response>{
    (: We only accept GET requests :)
    if (not(request:get-method() eq 'GET')) then
        (response:set-status-code(405),
        <error>Method not allowed</error>)
    else if(empty($id) or $id eq '') then
        (response:set-status-code(400),
        <error>Bad request: no id</error>)
    else
        (: work out document location :)
        let $doc :=
            if ($type eq 'ms') then
                $config:mpese-tei-corpus-mss || '/' || $id || ".xml"
            else
                $config:mpese-tei-corpus-texts || '/' || $id || ".xml"
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