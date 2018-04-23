xquery version "3.1";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

(: Create a witness list for a text by trawling the manuscripts for links with witness details :)

(: Create a label for the manuscript :)
declare function local:ms-label($ms) {
    let $ident := doc($ms)//tei:text/tei:body/tei:msDesc/tei:msIdentifier
    let $label_repo := if (normalize-space($ident/tei:repository/string()) = '') then () else $ident/tei:repository/string()
    let $label_collection := if (normalize-space($ident/tei:collection/string()) = '') then () else $ident/tei:collection/string()
    let $label_id := if (normalize-space($ident/tei:idno/string()) = '') then () else $ident/tei:idno/string()
    return $label_repo || ', ' || $label_collection || ' ' || $label_id
};

(: Create a label for the locus :)
declare function local:locus($msItem) {

    let $locus := $msItem/tei:locus
    let $folio_prefix := if (fn:contains($locus, '-')) then ', ff.' else ', f.'
    return
        $folio_prefix || ' ' || replace($locus, '-', '–')
};

(: find any transcript for the witness :)
declare function local:find-transcript($msItem) {
    if (exists($msItem/tei:link[@type='t_witness'])) then
        (<ref xmlns="http://www.tei-c.org/ns/1.0" type="text" target="{fn:substring-after($msItem/tei:link[@type='t_witness']/@target/string(), 'texts/')}">Transcript</ref>, text{" of "})
    else
        ()
};

(: search mss for text witnesses :)
declare function local:process-mss($text) {
    for $msItem in collection('/db/mpese/tei/corpus/mss/')//tei:msItem[tei:link[@target='../texts/' || $text][@type='witness']] order by base-uri($msItem)
    return
        let $mss_link := '../mss/' || substring-after(base-uri($msItem), 'mss/')
        let $label := local:ms-label(base-uri($msItem))
        return
        <bibl xmlns="http://www.tei-c.org/ns/1.0">
            {local:find-transcript($msItem)}
            <ref type="ms" target="{$mss_link}">{$label}{local:locus($msItem)}</ref>
        </bibl>
};

(: find the witnesses for a text :)
declare function local:witnesses($text) {
    <listBibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="mss_witness_generated">{
        comment{'Generated by create_witness_list.xql (' || current-dateTime() || ')'},
        local:process-mss($text)
    }</listBibl>
};

for $text in collection('/mpese/tei/corpus/texts')
    let $name := substring-after(base-uri($text), '/texts/')
    let $witness := local:witnesses($name)
    return
        if (exists($text//tei:fileDesc/tei:sourceDesc/tei:listBibl[@xml:id='mss_witness_generated'])) then
                    update replace $text//tei:fileDesc/tei:sourceDesc/tei:listBibl[@xml:id='mss_witness_generated'] with $witness
                else
                    update insert $witness following $text//tei:fileDesc/tei:sourceDesc/tei:listBibl[@xml:id='mss_witness']