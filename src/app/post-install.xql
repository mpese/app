xquery version "1.0";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "modules/config.xqm";

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

(: set the group owner for certain paths (recursively) :)
local:chgrp-collection($config:mpese_group, $config:mpese-tei),
local:chgrp-collection($config:mpese_group, $config:mpese-word-docx),
local:chgrp-collection($config:mpese_group, $config:mpese-word-unzip),

(: set the group owner for certain paths (not recursively) :)
sm:chgrp($mpese-app-dashboard, $config:mpese_group),
sm:chown($mpese-app-dashboard, 'admin'),

(: change permission for certain paths :)
sm:chmod(xs:anyURI($config:mpese-tei), 'rwxrwxr-x'),

(: force login ... :)
sm:chmod(xs:anyURI($mpese-app-dashboard), 'r-xr-x---')