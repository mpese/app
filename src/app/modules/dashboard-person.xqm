xquery version "3.1";

module namespace dashboard-person = "http://mpese.rit.bris.ac.uk/dashboard/person/";

import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";
import module namespace mpese-person = "http://mpese.rit.bris.ac.uk/corpus/person/" at 'mpese-corpus-person.xqm';


declare function dashboard-person:total($node as node (), $model as map (*)) {
    mpese-person:total-count()
};

declare function dashboard-person:all($node as node (), $model as map (*)) {

    (: get all of the people :)
    let $all := mpese-person:all()

    for $person in $all
        return
            <div class='person'>
                {mpese-person:label($person)}
            </div>

};
