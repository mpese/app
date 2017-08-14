xquery version "1.0";

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

util:log('INFO', ('MPESE: Running the post-installation script ...')),

(: set the group owner for certain paths (recursively) :)
local:chgrp-collection($config:mpese_group, $config:mpese-tei-templates),
local:chgrp-collection($config:mpese_group, $config:mpese-tei-corpus-texts),
local:chgrp-collection($config:mpese_group, $config:mpese-tei-corpus-mss),
local:chgrp-collection($config:mpese_group, $config:mpese-word-docx),
local:chgrp-collection($config:mpese_group, $config:mpese-word-unzip),

(: set the group owner for certain paths (not recursively) :)
sm:chgrp($mpese-app-dashboard, $config:mpese_group),
sm:chown($mpese-app-dashboard, 'admin'),

(: change permission for certain paths :)
sm:chmod(xs:anyURI($config:mpese-tei-corpus-texts), 'rwxrwxr-x'),
sm:chmod(xs:anyURI($config:mpese-tei-corpus-mss), 'rwxrwxr-x'),

local:copy-text-template(),

(: force login ... :)
sm:chmod(xs:anyURI($mpese-app-dashboard), 'r-xr-x---'),

util:log('INFO', ('MPESE: The post-installation script has finished'))