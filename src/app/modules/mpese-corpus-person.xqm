xquery version "3.1";


module namespace mpese-person = 'http://mpese.rit.bris.ac.uk/corpus/person/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace utils = 'http://mpese.rit.bris.ac.uk/utils/' at 'utils.xql';

(: the number of people in the corpus :)
declare function mpese-person:total-count() {
    fn:count(collection($config:mpese-tei-corpus-people)//tei:person)
};

(: get all the people in an ordered manner ... looks inefficient :)
declare function mpese-person:all() {
    for $person in collection($config:mpese-tei-corpus-people)//tei:persName
        let $order_name := (
            if (fn:exists($person/tei:surname)) then
                concat($person/tei:surname, ', ', $person/tei:forename)
            else if (fn:exists($person/tei:name)) then
                $person/tei:name
            else
                fn:normalize-space($person/string()))
    order by $order_name
    return $person
};

(: get a person by id :)
declare function mpese-person:person-by-id($pid) {
    let $results := collection($config:mpese-tei-corpus-people)//tei:person[@xml:id=$pid]
    return
        if (fn:count($results) > 0) then
            $results[1]
        else
            ""
};

(: basic label :)
declare function mpese-person:label($persName as node()?) as xs:string {
    if (fn:exists($persName/tei:surname)) then
        concat($persName/tei:surname, ', ', $persName/tei:roleName, ' ', $persName/tei:forename)
    else if (fn:exists($persName/tei:name)) then
        $persName/tei:name
    else
        fn:normalize-space($persName/string())
};


declare function mpese-person:person-label($person as node()) as node() {
    <h1 class="align-center">{if (fn:count($person//tei:persName/*/fn:string()) > 1) then
            fn:string-join($person//tei:persName/*/fn:string(), ' ')
         else fn:normalize-space($person//tei:persName/fn:string())}</h1>
};

(: ---------- TEMPLATE FUNCTIONS ----------- :)

(:~
 : Adds the person details and makes them available to other methods.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $text     the ID of the person.
 : @return a map with the TEI/XML of the <person/>
 :)
declare function mpese-person:person($node as node (), $model as map (*), $person_id as xs:string) {

    let $person := mpese-person:person-by-id($person_id)

    return
        map { "person" := $person, "id" := $person_id}
};

(:~
 : Provides a link back to the search if the cookies have the value.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $text     filename of the TEI/XML document
 : @return a link to the original search
 :)
declare function mpese-person:search-nav($node as node (), $model as map (*)) {
    utils:search-nav('../../')
};

(:~
 : Provide a title for the person page.
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @return a map with the TEI/XML of the <person/>
 :)
declare function mpese-person:title($node as node (), $model as map (*)) {

    mpese-person:person-label($model('person'))
};

declare function mpese-person:bibliographic($node as node (), $model as map (*)) {
    <div>{
        let $person := $model('person')
        let $birth :=   if ($person/tei:birth/tei:date/string())
                            then <p><strong>Birth:</strong>{text {' '}, $person/tei:birth/tei:date/string()}</p>
                        else ()
        let $death :=   if ($person/tei:death/tei:date/string())
                            then <p><strong>Death:</strong>{text {' '}, $person/tei:death/tei:date/string()}</p>
                        else ()
        let $nationality := if ($person/tei:nationality/string())
                            then <p><strong>Nationality:</strong>{text {' '}, $person/tei:nationality/string()}</p>
                        else ()
        let $occupation := if ($person/tei:occupation/string())
                            then <p><strong>Occupation:</strong>{text {' '}, $person/tei:occupation/string()}</p>
                        else ()
        let $details := ($birth, $death, $nationality, $occupation)
        return
            if (empty($details)) then <p>No details</p> else $details
    }</div>
};

declare function mpese-person:further-reading($node as node (), $model as map (*)) {
    <div>{
        let $person := $model('person')
        let $bibl :=   if ($person/tei:listBibl/string())
                            then <ul>{for $item in $person/tei:listBibl/tei:bibl return <li>{$item/string()}</li>}</ul>
                        else (<p>No details</p>)
        return
            $bibl
    }</div>
};

declare function mpese-person:author($node as node (), $model as map (*)) {
    <div>{
        let $id := '../people/people.xml#' || $model('id')
        let $texts := fn:collection($config:mpese-tei-corpus-texts)//tei:teiHeader/tei:fileDesc/tei:titleStmt[tei:author/tei:persName/@corresp = $id]
        let $text_list := if (fn:count($texts) > 0) then
                            <ul>{
                                for $text in $texts
                                let $uri := fn:base-uri($text)
                                let $name := utils:name-from-uri($uri)
                                return <li><a href="../t/{$name}.html">{$text/tei:title/string()}</a></li>
                            }</ul>
                          else (<p>No texts</p>)
        return
            $text_list
    }</div>
};