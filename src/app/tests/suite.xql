xquery version "3.1";

import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

import module namespace test-search = "http://mpese.ac.uk/corpus/search/test/" at "test-mpese-corpus-search.xql";
import module namespace test-text = "http://mpese.ac.uk/corpus/text/test/" at "test-mpese-corpus-text.xql";

test:suite(
    (
        inspect:module-functions(xs:anyURI("test-mpese-corpus-search.xql")),
        inspect:module-functions(xs:anyURI("test-mpese-corpus-text.xql"))
    )
)