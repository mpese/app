xquery version "1.0";

import module namespace util = "http://exist-db.org/xquery/util";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "modules/config.xqm";


(: Create the mpese group :)
declare function local:make-group($group, $desc) {
    if (not(sm:group-exists($group))) then
        sm:create-group($group, $desc)
    else
        ()
};

(: create collections - tokenize path and pass to recursive function :)
declare function local:create-collection($collection) {
    if (not(xmldb:collection-available($collection))) then
        let $components := fn:tokenize($collection, '/')
        return (
            local:create-collection-recursive($components[1], fn:subsequence($components, 2))
        )
    else
        ()
};

(: create a collection path if it doesn't exist:)
declare function local:create-collection-x($base, $collection) {
    if (not(xmldb:collection-available(concat($base, '/', $collection)))) then
        xmldb:create-collection($base, $collection)
    else
        ()
};

(: recursive function so we can create a path/collection :)
declare function local:create-collection-recursive($base, $components) {
    if (exists($components)) then
        let $collection := concat($base, '/', $components[1])
        return (
            local:create-collection-x($base, $components[1]),
            local:create-collection-recursive($collection, fn:subsequence($components, 2))

        )
    else
        ()
};

(: create the collections for storing documents :)
declare function local:make-collections() {
    (
    (: tei xml :)
    local:create-collection($config:mpese-tei-templates),
    local:create-collection($config:mpese-tei-corpus-texts),
    local:create-collection($config:mpese-tei-corpus-mss),
    local:create-collection($config:mpese-tei-corpus-people),
    local:create-collection($config:mpese-tei-corpus-places),
    local:create-collection($config:mpese-tei-corpus-meta),

    (: normalized text :)
    local:create-collection($config:mpese-normalized-texts),

    (: docx storage  :)
    local:create-collection($config:mpese-word-docx),

    (: docx unzipped  :)
    local:create-collection($config:mpese-word-unzip)
    )
};

util:log('INFO', ('MPESE: Running the pre-installation script ...')),

(: create group that will own collections :)
util:log('INFO', ('MPESE: Creating users and groups.')),
local:make-group($config:mpese_group, $config:mpese_group_desc),

(: create collections :)
util:log('INFO', ('MPESE: Creating collections.')),
local:make-collections(),

util:log('INFO', ('MPESE: The pre-installation script has finished'))