xquery version "3.1";

module namespace mpese-mss = 'http://mpese.rit.bris.ac.uk/corpus/mss/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';

(: get the list of mss documents :)
declare function mpese-mss:all-docs() {
    xmldb:get-child-resources($config:mpese-tei-corpus-mss)
};

(: get a single doc of mss documents :)
declare function mpese-mss:doc($doc) {
    fn:doc(concat($config:mpese-tei-corpus-mss, '/', $doc))
};

(: get the mss identifier - holds details of repository and mss shelf mark :)
declare function mpese-mss:identifier($mss_doc) {
    $mss_doc/tei:TEI/tei:text/tei:body/tei:msDesc/tei:msIdentifier
};

(: get the mss name :)
declare function mpese-mss:name($mss_doc) {
    $mss_doc//tei:body/tei:msDesc/tei:msIdentifier/tei:msName/text()
};

(: mss title - use the repo, collection, idno :)
declare function mpese-mss:title($mss_doc) {
    let $ident := mpese-mss:identifier($mss_doc)
    return
        concat($ident/tei:repository, ': ', $ident/tei:collection, ', ', $ident/tei:idno)
};



(: ---------- Functions to help render content  ----------- :)


(:~
 : Create a label for the MSS that a text comes from.
 :
 : @param $mss  the <msIdentifier/> element from the MSS.
 : @return a string representing the MSS details
 :)
declare function mpese-mss:ident-label($msIdentifier as element()?) as xs:string {
    if (count($msIdentifier/*) > 0) then
        $msIdentifier/tei:repository || ', ' || $msIdentifier/tei:collection || ', ' || $msIdentifier/tei:idno
    else
        "No manuscript details."
};


(: ---------- TEMPLATE FUNCTIONS ----------- :)

(:~
 : Adds the mss document to the model, so that it can be used by subsequent calls
 :
 : @param $node     the HTML node being processes
 : @param $model    application data
 : @param $mss      filename of the TEI/XML document
 : @return a map with the TEI/XML of the mss
 :)
declare function mpese-mss:mss($node as node (), $model as map (*), $mss as xs:string) {

    let $doc := doc(concat($config:mpese-tei-corpus-mss, '/', $mss))//tei:TEI
    return
        map { "mss" := $doc}
};

declare function mpese-mss:mss-ident($node as node (), $model as map (*)) {

    let $msIdentifier := $model('mss')//tei:body/tei:msDesc/tei:msIdentifier
    return
        <h2>{mpese-mss:ident-label($msIdentifier)}</h2>
};