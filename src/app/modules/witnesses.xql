xquery version "3.1";


declare namespace json="http://www.json.org";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

declare option exist:serialize "method=json media-type=text/javascript";

import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';
import module namespace mpese-text = 'http://mpese.rit.bris.ac.uk/corpus/text/' at 'mpese-corpus-text.xqm';
import module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/' at 'mpese-corpus-mss.xqm';

let $file := request:get-parameter('file','')

return
    if(empty($file) or $file eq '') then
        (response:set-status-code(400),
        <error>Bad request: no filename</error>)
    else if (not(doc-available($config:mpese-tei-corpus-texts || '/' || $file))) then
        (response:set-status-code(404),
        <error>Bad request: document not found</error>)
    else

        let $doc := doc($config:mpese-tei-corpus-texts || '/' || $file)

        let $ms_details :=  mpese-text:mss-details($doc//tei:TEI)

        let $text := mpese-mss:ident-label($ms_details) || mpese-text:folios($doc)

        let $node : = <nodes><id>1</id><label>{$text}</label><group>1</group></nodes>

        let $witnesses := for $witness at $pos in $doc//tei:listBibl[@xml:id="mss_witness_generated"]/tei:bibl
                            let $label := $witness//tei:ref[@type="ms"]/string()
                            return <nodes><id>{$pos + 1}</id><label>{$label}</label><group>{$pos + 1}</group></nodes>

        let $nodes := ($node, $witnesses)

        let $links := for $witness in $witnesses return
                        <links><source>{$node/id/string()}</source><target>{$witness/id/string()}</target></links>
        return
            <graph>{$nodes}{$links}</graph>