xquery version "3.0";

module namespace config = "http://mpese.rit.bris.ac.uk/config";

declare namespace templates = "http://exist-db.org/xquery/templates";
declare namespace repo = "http://exist-db.org/xquery/repo";
declare namespace expath = "http://expath.org/ns/pkg";

(: Determine the root of the application :)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;


(: users and groups :)
declare variable $config:mpese_group := 'mpese';
declare variable $config:mpese_group_desc := 'The MPESE project';

(: collection paths :)
declare variable $config:db-root := '/db';
declare variable $config:mpese-root := concat($config:db-root, '/mpese');
declare variable $config:mpese-word-root := concat($config:mpese-root, '/word');
declare variable $config:mpese-tei := concat($config:mpese-root, '/tei');
declare variable $config:mpese-tei-templates := concat($config:mpese-tei, '/templates');
declare variable $config:mpese-tei-corpus := concat($config:mpese-tei, '/corpus');
declare variable $config:mpese-tei-corpus-texts := concat($config:mpese-tei-corpus, '/texts');
declare variable $config:mpese-tei-corpus-mss := concat($config:mpese-tei-corpus, '/mss');
declare variable $config:mpese-tei-corpus-people := concat($config:mpese-tei-corpus, '/people');
declare variable $config:mpese-tei-corpus-places := concat($config:mpese-tei-corpus, '/places');
declare variable $config:mpese-tei-corpus-meta := concat($config:mpese-tei-corpus, '/meta');
declare variable $config:mpese-word-docx := concat($config:mpese-word-root, '/docx');
declare variable $config:mpese-word-unzip := concat($config:mpese-word-root, '/unzip');

(: The app data :)
declare variable $config:data-root := $config:app-root || "/data";

(: The repo descriptor file :)
declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

(: The expath package file :)
declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare variable $config:project := doc(concat($config:data-root, "/project.xml"))/project;
declare variable $config:app-abbrev := $config:project/abbr/text();

(: tei template filename :)
declare variable $config:tei-template-filename := 'mpese_text_template.xml';

(: project metadata file :)
declare variable $config:mpese-meta-filename := 'mpese.xml';

(: tei template that can be updated by researchers :)
declare variable $config:tei-template := concat($config:mpese-tei-templates, '/', $config:tei-template-filename);

(: tei meta data that can be updated by researchers :)
declare variable $config:tei-meta := concat($config:mpese-tei-corpus-meta, '/', $config:mpese-meta-filename);

(: tei template distributed by app (copied to a place the researchers can update if the file doesn't exist :)
declare variable $config:tei-template-app := concat($config:app-root, '/modules/', $config:tei-template-filename);

(: preferred date-time format (files :)
declare variable $config:date-time-fmt := '[D01]/[M01]/[Y0001] [H01]:[m01]:[s01]';

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare %templates:wrap function config:app-abbrev($node as node(), $model as map(*)) as text() {
    $config:project/abbr/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{request:get-attribute("$exist:controller")}</td>
            </tr>
        </table>
};