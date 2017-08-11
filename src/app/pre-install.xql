xquery version "1.0";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: groups :)
declare variable $mpese_group := 'mpese';
declare variable $mpese_group_desc := 'The MPESE project';

(: collection paths :)
declare variable $db-root := '/db';
declare variable $mpese-root := concat($db-root, '/mpese');
declare variable $mpese-word-root := concat($mpese-root, '/word');
declare variable $mpese-tei := concat($mpese-root, '/tei');
declare variable $mpese-word-docx := concat($mpese-word-root, '/docx');
declare variable $mpese-word-unzip := concat($mpese-word-root, '/unzip');


(: Create the mpese group :)
declare function local:make-group() {
    if (not(sm:group-exists($mpese_group))) then
        sm:create-group($mpese_group, $mpese_group_desc)
    else
        ()
};

(: Create collections - tokenize path and pass to recursive function :)
declare function local:create-collection($collection) {
    if (not(xmldb:collection-available($collection))) then
        let $components := fn:tokenize($collection, '/')
        return (
            local:create-collection-recursive($components[1], fn:subsequence($components, 2))
        )
    else
        ()
};

(: Create a collection path if it doesn't exist:)
declare function local:create-collection-x($base, $collection) {
    if (not(xmldb:collection-available(concat($base, '/', $collection)))) then
        xmldb:create-collection($base, $collection)
    else
        ()
};


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
    local:create-collection($mpese-tei),

    (: docx storage  :)
    local:create-collection($mpese-word-docx),

    (: docx unzipped  :)
    local:create-collection($mpese-word-unzip)
    )
};

local:make-group(),
local:make-collections()