xquery version "3.1";

import module namespace util = "http://exist-db.org/xquery/util";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "modules/config.xqm";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare variable $mpese-app-dashboard := concat($config:db-root, '/apps/mpese/dashboard');


declare function local:chgrp-collection-recursive($group, $base, $components) {
    if (exists($components)) then
        let $collection := concat($base, '/', $components[1])
        return (
            sm:chgrp($collection, $group),
            local:chgrp-collection-recursive($group, $collection, fn:subsequence($components, 2))
        )
    else
        ()
};

(: Create collections - tokenize path and pass to recursive function :)
declare function local:chgrp-collection($group, $collection) {

    let $components := fn:tokenize($collection, '/')
    return (
        local:chgrp-collection-recursive($group, $components[1], fn:subsequence($components, 2))
    )
};

(: Copy text template into storage if it doesn't exist :)
declare function local:copy-text-template() {

    if (not (doc-available($config:tei-template))) then
        (
            xmldb:copy(concat($config:app-root, '/modules/'), $config:mpese-tei-templates, $config:tei-template-filename),
            sm:chmod(xs:anyURI($config:tei-template), 'rwxrwxr-x'),
            util:log('INFO', concat('Change group of ', $config:tei-template)),
            sm:chgrp(xs:anyURI($config:tei-template), $config:mpese_group)
        )
    else
        ()
};

(: Copy text metadata into storage if it doesn't exist :)
declare function local:copy-mpese-meta() {

    if (not (doc-available($config:tei-meta))) then
        (
            xmldb:copy(concat($config:app-root, '/modules/'), $config:mpese-tei-corpus-meta, $config:mpese-meta-filename),
            sm:chmod(xs:anyURI($config:mpese-tei-corpus-meta), 'rwxrwxr-x'),
            util:log('INFO', concat('Change group of ', $config:mpese-tei-corpus-meta)),
            sm:chgrp(xs:anyURI($config:mpese-tei-corpus-meta), $config:mpese_group)
        )
    else
        ()
};

(: Copy indices :)
declare function local:copy-mpese-indices() {
    (
    xmldb:copy(concat($config:app-root, '/indices/'),
               concat('/db/system/config', $config:mpese-tei-corpus-texts), 'collection-texts.xconf'),
    xmldb:rename(concat('/db/system/config', $config:mpese-tei-corpus-texts), 'collection-texts.xconf', 'collection.xconf')
    )

};

(: We don't want folders in the app world readable :)
declare function local:update-app-other($collection) {

    util:log('INFO', ('Found collection in app: ' || $collection)),
    sm:chmod($collection, 'rwxr-x--x'),

    for $coll in xmldb:get-child-collections($collection)
        return local:update-app-other($collection || '/' || $coll)

};

util:log('INFO', ('MPESE: Running the post-installation script ...')),

util:log('INFO', ('MPESE: Remove read access to Other for app collections')),
local:update-app-other('/db/apps/mpese/'),

(: set the group owner for certain paths (recursively) :)
local:chgrp-collection($config:mpese_group, $config:mpese-tei-templates),
local:chgrp-collection($config:mpese_group, $config:mpese-tei-corpus-texts),
local:chgrp-collection($config:mpese_group, $config:mpese-tei-corpus-mss),
local:chgrp-collection($config:mpese_group, $config:mpese-tei-corpus-people),
local:chgrp-collection($config:mpese_group, $config:mpese-tei-corpus-places),
local:chgrp-collection($config:mpese_group, $config:mpese-tei-corpus-meta),
local:chgrp-collection($config:mpese_group, $config:mpese-word-docx),
local:chgrp-collection($config:mpese_group, $config:mpese-word-unzip),

(: set the group owner for certain paths (not recursively) :)
sm:chgrp($mpese-app-dashboard, $config:mpese_group),
sm:chown($mpese-app-dashboard, 'admin'),

(: change permission for certain paths :)
sm:chmod(xs:anyURI($config:mpese-tei-corpus-texts), 'rwxrwxr-x'),
sm:chmod(xs:anyURI($config:mpese-tei-corpus-mss), 'rwxrwxr-x'),
sm:chmod(xs:anyURI($config:mpese-tei-corpus-people), 'rwxrwxr-x'),
sm:chmod(xs:anyURI($config:mpese-tei-corpus-places), 'rwxrwxr-x'),
sm:chmod(xs:anyURI($config:mpese-tei-corpus-meta), 'rwxrwxr-x'),
sm:chmod(xs:anyURI($config:mpese-word-docx), 'rwxrwxr-x'),
sm:chmod(xs:anyURI($config:mpese-word-unzip), 'rwxrwxr-x'),

local:copy-text-template(),

local:copy-mpese-meta(),

local:copy-mpese-indices(),

xmldb:reindex($config:mpese-tei-corpus-texts),

(: force login ... :)
sm:chmod(xs:anyURI($mpese-app-dashboard), 'r-xr-x---'),

util:log('INFO', ('MPESE: The post-installation script has finished'))