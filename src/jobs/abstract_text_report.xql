xquery version "3.1";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:item-separator "&#xa;";
declare option output:method "text";



declare function local:create-report() {

    (: missing :)
    let $missing_abstract_text := for $doc in collection('/db/mpese/tei/corpus/texts/')
        return if (not($doc//tei:profileDesc/tei:abstract/tei:p/string())) then fn:base-uri($doc) else ()

    return (
    ("MPESE abstract for texts report"),
    (current-dateTime()),
    ("========================================"),
    ("Total texts without abstracts/introductions: " || count($missing_abstract_text)),
    ("========================================"),
    for $uri in $missing_abstract_text order by $uri
        return $uri
    )
};

declare function local:send-report($report, $to, $from) {

    let $email := <mail>
       <from>{$from}</from>
       <to>{$to}</to>
       <cc>{$from}</cc>
       <subject>MPESE proofreading report</subject>
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