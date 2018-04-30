xquery version "3.1";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:item-separator "&#xa;";
declare option output:method "text";

(: http://www.xqueryfunctions.com/xq/functx_value-except.html :)
declare function  local:value-except
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[not(.=$arg2)])
 } ;

declare function local:create-report() {

    (: get all the proof read :)
    let $proof_read := for $doc in collection('/db/mpese/tei/corpus/texts/')
                        where $doc//tei:revisionDesc/tei:listChange/tei:change[@status eq "proofread"]
                        return
                        base-uri($doc)

    (: all documents :)
    let $all := for $doc in collection('/db/mpese/tei/corpus/texts/') return base-uri($doc)

    (: those not proof read :)
    let $not_proof_read := local:value-except($all, $proof_read)

    let $resp := distinct-values(collection('/db/mpese/tei/corpus/texts/')//tei:change[@status eq "proofread"]/@who/string())
    let $counts := for $person in $resp
                    let $count := count(collection('/db/mpese/tei/corpus/texts/')//tei:change[@status eq "proofread" and @who eq $person])
                    let $p_details := doc('/db/mpese/tei/corpus/meta/mpese.xml')//tei:respStmt[@xml:id = substring-after($person, '#')]/tei:name/string()
                    order by $count descending
                    return $p_details || " (" || $count || ")"


    return (
    ("MPESE proofreading report"),
    (current-dateTime()),
    ("========================================"),
    ("Total texts: " || count($all)), ("Texts proofread: " || count($proof_read)),
    ("To be proofread: (" || count($not_proof_read) || ")"),
    ("========================================"),
    ("Proofreading league table:"),
    ($counts),
    ("========================================"),
    for $uri in $not_proof_read order by $uri return $uri
    )
};

declare function local:send-report($report, $to, $from) {

    (: get all the proof read :)
    let $proof_read := for $doc in collection('/db/mpese/tei/corpus/texts/')
                        where $doc//tei:revisionDesc/tei:listChange/tei:change[@status eq "proofread"]
                        return
                        base-uri($doc)

    (: all documents :)
    let $all := for $doc in collection('/db/mpese/tei/corpus/texts/') return base-uri($doc)

    (: those not proof read :)
    let $not_proof_read := local:value-except($all, $proof_read)

    let $resp := distinct-values(collection('/db/mpese/tei/corpus/texts/')//tei:change[@status eq "proofread"]/@who/string())
    let $counts := for $person in $resp
                    let $count := count(collection('/db/mpese/tei/corpus/texts/')//tei:change[@status eq "proofread" and @who eq $person])
                    let $p_details := doc('/db/mpese/tei/corpus/meta/mpese.xml')//tei:respStmt[@xml:id = substring-after($person, '#')]/tei:name/string()
                    order by $count descending
                    return $p_details || " (" || $count || ")"


    let $report := (
    ("MPESE proofreading report"),
    (current-dateTime()),
    ("========================================"),
    ("Total texts: " || count($all)), ("Texts proofread: " || count($proof_read)),
    ("To be proofread: (" || count($not_proof_read) || ")"),
    ("========================================"),
    ("Proofreading league table:"),
    ($counts),
    ("========================================"),
    for $uri in $not_proof_read order by $uri return $uri
    )

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