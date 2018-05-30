xquery version "3.1";

(:~
: Return a list of text XML documents. We use this so we can extract all of the texts as text files
: or PDFs for processing or archiving
:)

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";

<texts>{
    for $doc in collection($config:mpese-tei-corpus-texts)
        return
            <text uri="{base-uri($doc)}"/>
}</texts>
