xquery version "3.1";

module namespace mpese-search = 'http://mpese.ac.uk/corpus/search/';

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace config = 'http://mpese.rit.bris.ac.uk/config' at 'config.xqm';

(: ---------- TEMPLATE FUNCTIONS ----------- :)


(: default search, i.e. no search results defined  :)
declare function mpese-search:default($node as node (), $model as map (*))  {
    <div id="search-results">{}
        <p>Search results go here.</p>
    </div>
};