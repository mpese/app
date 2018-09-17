xquery version "3.1";

(:~
: Return a list of text XML documents. We use this so we can extract all of the texts as text files
: or PDFs for processing or archiving.
:)

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "../modules/config.xqm";

if (fn:not(request:get-method() eq 'GET')) then
    (response:set-status-code(405), <response><error>Method not allowed</error></response>)
else
<texts>{
    for $doc in fn:collection($config:mpese-tei-corpus-texts)
        return
            <text uri="{fn:base-uri($doc)}"/>
}</texts>
