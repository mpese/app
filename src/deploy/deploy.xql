xquery version "3.0";
 
import module namespace repo = "http://exist-db.org/xquery/repo";

declare variable $xar := "/db/xar_files/mpese-app-@APPVERSION@.xar";
 
try {
    repo:install-and-deploy-from-db($xar)
} catch * {
    <error>Caught error {$err:code}: {$err:description}</error>
}
