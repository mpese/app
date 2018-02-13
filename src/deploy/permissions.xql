xquery version "3.0";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";

(: force login for all (demo) ... :)
sm:chgrp(xs:anyURI('/db/apps/mpese/'), 'mpese'),
sm:chown(xs:anyURI('/db/apps/mpese/'), 'admin'),
sm:chmod(xs:anyURI('/db/apps/mpese/'), 'r-xr-x---')