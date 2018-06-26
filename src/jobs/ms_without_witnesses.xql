xquery version "3.1";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:item-separator "&#xa;";
declare option output:method "text";



declare function local:create-report() {

    (: missing :)
    let $missing_witness_ms := for $doc in collection('/db/mpese/tei/corpus/mss/')
        return if (not($doc//tei:link[@type="witness" or @type="t_witness"])) then base-uri($doc) else ()

    return (
    ("MPESE manuscripts without links to witnesses"),
    (current-dateTime()),
    ("========================================"),
    ("Total mss without links to witnesses: " || count($missing_witness_ms)),
    ("========================================"),
    for $uri in $missing_witness_ms order by $uri
        return $uri
    )
};

declare function local:send-report($report, $to, $from) {

    let $email := <mail>
       <from>{$from}</from>
       <to>{$to}</to>
       <cc>{$from}</cc>
       <subject>MPESE mss without links to witnesses</subject>
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
