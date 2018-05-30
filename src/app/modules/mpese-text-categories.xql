xquery version "3.1";

(:~
: Return a list of the text XML documents and their categories.
:)

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

<texts>{
    for $doc in collection($config:mpese-tei-corpus-texts)
    return
        let $uri := base-uri($doc)
        let $categories := string-join($doc//tei:keywords/tei:term/string(), ';')
        return
            <text uri="{$uri}" categories="{$categories}"/>
}</texts>