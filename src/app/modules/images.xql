xquery version "3.1";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

declare option exist:serialize "method=json media-type=text/javascript";

import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';


let $type := request:get-parameter('type', 'ms')
let $id := request:get-parameter('id', '')

return
    <response>{
    if(empty($id) or $id eq '') then
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
                return <image>{$image/@url/string()}</image>
            else
                <image/>
        return
        (response:set-status-code(200),
        <results>{if (count($results) eq 0) then <image/> else $results}</results>
        )
    }</response>