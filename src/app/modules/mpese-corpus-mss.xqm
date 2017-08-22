xquery version "3.1";

module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';

(: get the list of mss docunts :)
declare function mpese-mss:docs() {
    xmldb:get-child-resources($config:mpese-tei-corpus-mss)
};

declare function mpese-mss:list-mss() {
    let $docs := mpese-mss:docs()
    return
        <table class='table table-respossive'>
            <thead>
                <tr>
                    <th>Repository</th>
                    <th>Collection</th>
                    <th>ID No.</th>
                </tr>
            </thead>
            <tbody>{
                        for $doc in $docs
        order by $doc ascending
            let $mss := fn:doc(concat($config:mpese-tei-corpus-mss, '/', $doc))
            return
            <tr>
                <td>{$mss/tei:TEI/tei:text/tei:body/tei:msDesc/tei:msIdentifier/tei:repository}</td>
                <td>{$mss/tei:TEI/tei:text/tei:body/tei:msDesc/tei:msIdentifier/tei:collection}</td>
                <td>{$mss/tei:TEI/tei:text/tei:body/tei:msDesc/tei:msIdentifier/tei:idno}</td>
            </tr>
            }</tbody>
        </table>
};