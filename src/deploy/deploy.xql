xquery version "3.0";
 
import module namespace repo = "http://exist-db.org/xquery/repo";
 
declare variable $pkg := "http://mpese.rit.bris.ac.uk";
declare variable $xar := "/db/xar_files/mpese-@APPVERSION@-.xar";
 
repo:undeploy($pkg),
repo:remove($pkg),
repo:install-and-deploy-from-db($xar)
