xquery version "3.1";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace xi = 'http://www.w3.org/2001/XInclude';

(: Create a label for the manuscript :)
declare function local:ms-label($ms) {
    let $ident := doc($ms)//tei:text/tei:body/tei:msDesc/tei:msIdentifier
    let $label_repo := if (normalize-space($ident/tei:repository/string()) = '') then () else $ident/tei:repository/string()
    let $label_collection := if (normalize-space($ident/tei:collection/string()) = '') then () else $ident/tei:collection/string()
    let $label_id := if (normalize-space($ident/tei:idno/string()) = '') then () else $ident/tei:idno/string()
    return $label_repo || ', ' || $label_collection || ' ' || $label_id
};

(: get the URI for an MS :)
declare function local:ms-uri($text) {
    let $mss-xi := $text//tei:fileDesc/tei:sourceDesc/tei:msDesc/xi:include
    let $mss-uri := '/db/mpese/tei/corpus/mss' || fn:substring-after($mss-xi/@href/string(), '../mss')
    return $mss-uri
};

declare function local:ms-p($label) {
    <p xmlns="http://www.tei-c.org/ns/1.0" xml:id='ms-label-generated'>{$label,comment{'Generated mss-label-job.xql (' || current-dateTime() || ')'}}</p>
};

for $text in collection('/db/mpese/tei/corpus/texts')
    let $ms-uri := local:ms-uri($text)
    let $ms-label := local:ms-label($ms-uri)
    let $p := local:ms-p($ms-label)
    return
    if (exists($text//tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:p[@xml:id='ms-label-generated'])) then
        update replace $text//tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:p[@xml:id='ms-label-generated'] with $p
    else
        update insert $p following $text//tei:fileDesc/tei:sourceDesc/tei:msDesc/xi:include