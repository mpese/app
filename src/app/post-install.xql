xquery version "1.0";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";

(: groups :)
declare variable $mpese_group := 'mpese';

(: collection paths :)
declare variable $db-root := '/db';
declare variable $mpese-root := concat($db-root, '/mpese');
declare variable $mpese-word-root := concat($mpese-root, '/word');
declare variable $mpese-tei := concat($mpese-root, '/tei');
declare variable $mpese-word-docx := concat($mpese-word-root, '/docx');
declare variable $mpese-word-unzip := concat($mpese-word-root, '/unzip');
declare variable $mpese-app-dashboard := concat($db-root, '/apps/mpese/dashboard');


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
local:chgrp-collection($mpese_group, $mpese-tei),
local:chgrp-collection($mpese_group, $mpese-word-docx),
local:chgrp-collection($mpese_group, $mpese-word-unzip),

(: set the group owner for certain paths (not recursively) :)
sm:chgrp($mpese-app-dashboard, $mpese_group),
sm:chown($mpese-app-dashboard, 'admin'),

(: change permission for certain paths :)
sm:chmod($mpese-tei, 'rwxrwxr-x'),
(: force login ... :)
sm:chmod($mpese-app-dashboard, 'r-xr-x---')