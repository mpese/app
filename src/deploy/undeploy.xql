xquery version "3.0";
 
import module namespace repo = "http://exist-db.org/xquery/repo";
 
declare variable $pkg := "http://mpese.rit.bris.ac.uk";

try {
    repo:undeploy($pkg),
    repo:remove($pkg)
} catch * {
    <error>Caught error {$err:code}: {$err:description}</error>
}
