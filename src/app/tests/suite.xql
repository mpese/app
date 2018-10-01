xquery version "3.1";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

test:suite(
        (
            inspect:module-functions(xs:anyURI("test-mpese-corpus-search.xql")),
            inspect:module-functions(xs:anyURI("test-mpese-corpus-text.xql")),
            inspect:module-functions(xs:anyURI("test-mpese-corpus-mss.xql")),
            inspect:module-functions(xs:anyURI("test-mpese-corpus-people.xql")),
            inspect:module-functions(xs:anyURI("test-mpese-access-tests.xql")),
            inspect:module-functions(xs:anyURI("test-mpese-expected-pages.xql"))
        )
)