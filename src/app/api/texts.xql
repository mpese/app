xquery version "3.1";

(:~
: Return a list of text XML documents. We use this so we can extract all of the texts as text files
: or PDFs for processing or archiving.
:)

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "../modules/config.xqm";

let $type := request:get-parameter('type', 'all')
return
    if (fn:not(request:get-method() eq 'GET')) then
        (response:set-status-code(405), <response><error>Method not allowed</error></response>)
    else
    <texts>{
        if ($type eq 'all') then
            for $doc in fn:collection($config:mpese-tei-corpus-texts)
               return
                    <text uri="{fn:base-uri($doc)}"/>
        else
            for $doc in fn:collection($config:mpese-tei-corpus-texts)
                return
                    if (fn:not(fn:normalize-space($doc//tei:text[1]/tei:body[1]/fn:string()) eq '')) then
                         <text uri="{fn:base-uri($doc)}"/>
                    else
                        ()
}</texts>
