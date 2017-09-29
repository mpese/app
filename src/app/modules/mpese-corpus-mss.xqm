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
