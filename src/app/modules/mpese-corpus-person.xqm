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
        map { "person" := $person}
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

    let $person := $model('person')

    return
        <h2>{fn:string-join($person//tei:persName/*/string(), ' ')}</h2>
};