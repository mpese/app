xquery version "3.0";

module namespace config = "http://mpese.rit.bris.ac.uk/config";

declare namespace templates = "http://exist-db.org/xquery/templates";
declare namespace repo = "http://exist-db.org/xquery/repo";
declare namespace expath = "http://expath.org/ns/pkg";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

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
declare variable $config:mpese-normalized := concat($config:mpese-root, '/normalized');
declare variable $config:mpese-normalized-texts := concat($config:mpese-normalized , '/texts');
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
 : We pass the name of a document as an attribute. Work out the URI so we can get a title
 : to be used in the metadata of document.
 :
 : @return a document URI
 :)
declare function config:content-uri() {
    if (fn:not(fn:empty(request:get-attribute('text')))) then
        $config:mpese-tei-corpus-texts || '/' || request:get-attribute('text')
    else if (fn:not(fn:empty(request:get-attribute('mss')))) then
        $config:mpese-tei-corpus-mss || '/' || request:get-attribute('mss')
    else
        ()
};

declare function config:content-title($uri) {
    if ($uri) then fn:doc($uri)//tei:fileDesc/tei:titleStmt/tei:title/fn:string() else ()
};

declare function config:title() as text() {

    (: application name :)
    let $title := $config:expath-descriptor/expath:title/string()

    (: uri or text or ms :)
    let $content-uri := config:content-uri()

    (: title with name of text or mss if appropriate :)
    let $content-title := config:content-title($content-uri)
        return
            if (fn:not(fn:empty($content-title))) then
                text {fn:concat($content-title, ' | ', $title)}
            else
                text{$title}
};

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

(:~
 : Get the title of the application.
 :)
declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

(:~
 : Create a title for a page.
 :)
declare function config:page-title($node as node(), $model as map(*)) {
    <title>{config:title()}</title>
};

declare %templates:wrap function config:app-abbrev($node as node(), $model as map(*)) as text() {
    $config:project/abbr/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {

    (: get a title :)
    (: application name :)
    let $app-title := $config:expath-descriptor/expath:title/fn:string()

    (: uri or text or ms :)
    let $content-uri := config:content-uri()

    (: title with name of text or mss if appropriate :)
    let $content-title := config:content-title($content-uri)
    let $dc-title := if (fn:not(fn:empty($content-title))) then $content-title else $app-title

    (: authors :)
    let $authors := fn:doc($content-uri)//tei:fileDesc/tei:titleStmt/tei:author[fn:not(@role eq 'signatory')]/fn:normalize-space(fn:string())

    (: transcript contributors :)
    let $contribs := fn:doc($content-uri)//tei:fileDesc/tei:titleStmt/tei:respStmt/tei:name/fn:string()

    (: kewords :)
    let $keywords := fn:string-join(for $keyword in fn:doc($content-uri)//tei:keywords/tei:term/fn:string()
                            return if (fn:not($keyword eq '')) then $keyword else (), ', ')

    (: description :)
    let $description := fn:normalize-space(fn:doc($content-uri)//tei:profileDesc/tei:abstract/fn:string())

    (: languages :)
    let $languages := for $lang in fn:doc($content-uri)//tei:langUsage/tei:language/@ident/fn:string()
                            return if (fn:not($lang eq '')) then $lang else ()

    (: date :)
    let $date := fn:doc($content-uri)//tei:profileDesc/tei:creation/tei:date[1]/@when/fn:string()

    return
        (
            <meta name="dc:title" content="{$dc-title}"/>,
            for $author in $authors return if (fn:not($author eq '')) then <meta name="dc:reator" content="{$author}"/> else (),
            for $contrib in $contribs return if (fn:not($contrib eq '')) then <meta name="dc:contributor" content="{$contrib}"/> else (),
            if (fn:not($keywords eq '')) then <meta name="dc:keywords" content="{$keywords}"/> else (),
            if (fn:not($description eq '')) then <meta name="dc:description" content="{$description}"/> else (),
            for $lang in $languages return if (fn:not($lang eq '')) then <meta name="dc:language" content="{fn:lower-case($lang)}"/> else (),
            if (fn:not(fn:normalize-space($date) eq '')) then <meta name="dc:date" content="{$date}"/> else ()
        )
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

(:~
 : Provide a change log for those with preview access to the service.
 :)
declare function config:changes($node as node(), $model as map(*)) {

    let $changes := for $div in doc('/db/mpese/tei/corpus/meta/mpese.xml')//tei:text/tei:body/tei:div
                    order by $div/tei:head/tei:date/@when descending
                    return $div

    return
        <div>{

            for $change in $changes
            return
                <div class="well well-sm">
                <h3>{$change/tei:head/string()}</h3>
                <ul>{
                    for $item in $change/tei:list/tei:item
                    return
                        <li>{$item/string()}</li>
                }</ul>
                </div>
        }</div>

};