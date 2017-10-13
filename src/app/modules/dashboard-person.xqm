xquery version "3.1";

module namespace dashboard-person = "http://mpese.rit.bris.ac.uk/dashboard/person/";

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace mpese-person = "http://mpese.rit.bris.ac.uk/corpus/person/" at 'mpese-corpus-person.xqm';
import module namespace utils = "http://mpese.rit.bris.ac.uk/utils/";

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

(: total number of people :)
declare function dashboard-person:total($node as node (), $model as map (*)) {
    mpese-person:total-count()
};

(: show all the people :)
declare function dashboard-person:all($node as node (), $model as map (*)) {

    (: get all of the people :)
    let $all := mpese-person:all()
    return
        <ul>{
            for $person in $all
                let $id := $person/../@xml:id/string()
                return
                    <li class='person'><a href="./{$id}.html">{mpese-person:label($person)}</a></li>
        }</ul>
};

(: show an individual :)
declare function dashboard-person:details($node as node (), $model as map (*), $pid as xs:string) {

    let $person := mpese-person:person-by-id($pid)
    return
    if (fn:collection($config:mpese-tei-corpus-people)//*[@xml:id eq $pid]) then

        let $title := mpese-person:label($person/tei:persName)
        let $corresp := concat('../people/people.xml#', $pid)
        return
            <div>
                <h2>{$title}</h2>
                {
                    if (not(empty($person/tei:occupation))) then
                    <p><em>{$person/tei:occupation/string()}</em></p>
                    else ""
                }
                {
                    if (not(empty($person/tei:birth/tei:date))) then
                        <p><strong>Birth:</strong>&#x20;{$person/tei:birth/tei:date/string()}</p>
                    else ""
                }
                {
                    if (not(empty($person/tei:death/tei:date))) then
                        <p><strong>Death:</strong>&#x20;{$person/tei:death/tei:date/string()}</p>
                    else ""
                }
                {
                    let $results := collection($config:mpese-tei-corpus-texts)//tei:author[@corresp = $corresp]
                    return
                        if (count($results) > 0) then
                            <div>
                                <h5>Author</h5>
                                <ul>{
                                    for $result in $results
                                        let $root := root($result)
                                        let $uri := fn:base-uri($root)
                                        let $name := utils:name-from-uri($uri)
                                        let $title := $root//tei:titleStmt/tei:title/string()
                                        return
                                            <li><a href="../text/{$name}.html">{$title}</a></li>
                                }</ul>
                            </div>
                        else ""
                }
                {
                    if (count($person/tei:listBibl/tei:bibl)) then
                        <div>
                            <h5>Further reading</h5>
                            <ul>{
                                for $item in $person/tei:listBibl/tei:bibl
                                    return
                                        <li>{$item/string()}</li>
                            }</ul>
                        </div>
                    else ""
                }

            </div>
    else
        <p>Not found</p>
};
