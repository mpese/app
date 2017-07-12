xquery version "1.0";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";

declare variable $home external;

xdb:create-collection('/db', 'word_docs'),
()