xquery version "3.1";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:item-separator "&#xa;";
declare option output:method "text";


declare function local:create-report() {

    let $matches := for $doc in collection('/db/mpese/tei/corpus/mss/')//tei:link[@type="witness" or @type="t_witness"]
    let $uri := base-uri($doc)
    return if (doc($uri)//*[matches(comment(), "(\w+\.xml)")]) then $uri else ()

    let $uris := for $uri in distinct-values($matches) order by $uri return $uri

    return (
    ("MPESE mss with suspected incomplete witness data"),
    (current-dateTime()),
    ("========================================"),
    ("Total mss with suspected incomplete witness data: " || count($uris)),
    ("========================================"),
    for $uri in $uris order by $uri
        return $uri
    )
};

declare function local:send-report($report, $to, $from) {

    let $email := <mail>
       <from>{$from}</from>
       <to>{$to}</to>
       <cc>{$from}</cc>
       <subject>MPESE mss with suspected incomplete witness data</subject>
       <message>
         <text>{string-join($report, '&#xa;')}</text>
       </message>
    </mail>

    return mail:send-email($email, 'localhost', 'utf-8')
};

let $from := 'mike.a.jones@bristol.ac.uk'
let $to := ('s.verweij@bristol.ac.uk', 'r.t.bell@bham.ac.uk', 'n.c.millstone@bham.ac.uk')
let $report := local:create-report()
for $p in $to
    return local:send-report($report, $p, $from)
