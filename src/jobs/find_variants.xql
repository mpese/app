xquery version "3.1";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

(: get the list of versioned texts :)
declare function local:find-witnesses() {
    for $i in collection('/db/mpese/tei/corpus/texts/')
    where matches(document-uri($i), 'v\d*.xml$')
    order by document-uri($i)
    return document-uri($i)
};

(: get the distinct name of versioned texts :)
declare function local:distint-witness-names($all) {
    let $names := for $i in $all
        let $tmp := fn:substring-after($i, '/db/mpese/tei/corpus/texts/')
        return fn:replace($tmp, 'v\d*.xml$', '')
    return fn:distinct-values($names)
};

(: create an xml document for the variant texts :)
declare function local:catalogue-variants() {
    let $all-witnesses := local:find-witnesses()
    let $distinct-names := local:distint-witness-names($all-witnesses)
    return
        <texts>{
            for $name in $distinct-names
                return
                    <variants name="{$name}">{
                    for $doc in $all-witnesses
                    return
                        if (fn:contains($doc, $name)) then
                            <variant uri="{$doc}"/>
                        else
                            ()
                    }</variants>
        }</texts>
};


(: Create a group of links excluding 'this_doc' :)
declare function local:create-group($this_doc, $variants) {
    let $list := for $variant in $variants/variant
        return
            for $other_doc in $variant/@uri/string()
                return
                    if ($this_doc eq $other_doc) then
                        ()
                    else
                        <ptr target="{fn:substring-after($other_doc, '/db/mpese/tei/corpus/texts/')}" xmlns="http://www.tei-c.org/ns/1.0"/>

    return
        <linkGrp type="mpese_variants" xmlns="http://www.tei-c.org/ns/1.0">{$list}</linkGrp>
};

declare function local:process($variants) {
    (: ignore texts with only 1 version :)
    if (count($variants/variant) > 1) then
        (: go through each variant :)
        for $variant in $variants/variant
            (: get the uri of the current document :)
            let $this_doc := $variant/@uri/string()
            (: create a group that ommits the current document :)
            let $link_group := local:create-group($this_doc, $variants)
            return
                if (exists(doc($this_doc)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:editionStmt)) then
                    update replace doc($this_doc)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:linkGrp with $link_group
                else
                    update insert <editionStmt xmlns="http://www.tei-c.org/ns/1.0"><edition>{$link_group}</edition></editionStmt> preceding doc($this_doc)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt
    else
        ()
};

let $catalogue := local:catalogue-variants()


for $variants in $catalogue//variants
    return local:process($variants)