xquery version "3.1";


module namespace mpese-person = 'http://mpese.rit.bris.ac.uk/corpus/person/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";

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
            else $person/tei:name)
    order by $order_name
    return $person
};

(: basic label :)
declare function mpese-person:label($persName as node()) as xs:string {
    if (fn:exists($persName/tei:surname)) then
        concat($persName/tei:surname, ', ', $persName/tei:roleName, ' ', $persName/tei:forename)
    else
        $persName/tei:name
};