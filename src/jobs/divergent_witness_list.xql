xquery version "3.1";

(: Compare the generated list against the hand curated list :)

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

let $results := <results>{
    for $text in collection('/db/mpese/tei/corpus/texts/')
        let $uri := base-uri($text)
        let $witness_1 := count($text//tei:listBibl[@xml:id="mss_witness"]/tei:bibl)
        let $witness_2 := count($text//tei:listBibl[@xml:id="mss_witness_generated"]/tei:bibl)
        order by $uri
        return
            if ($witness_1 != $witness_2)  then
                <result><text>{$uri}</text><wit1>{$witness_1}</wit1><wit2>{$witness_2}</wit2></result>
            else
                ()
}</results>

return
    $results