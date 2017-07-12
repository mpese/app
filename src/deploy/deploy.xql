xquery version "3.0";
 
import module namespace repo = "http://exist-db.org/xquery/repo";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

declare variable $xar := "/db/xar_files/mpese-app-@APPVERSION@.xar";
 
try {
    repo:install-and-deploy-from-db($xar),
    xdb:create-collection('/db', 'word_docs')
} catch * {
    <error>Caught error {$err:code}: {$err:description}</error>
}
