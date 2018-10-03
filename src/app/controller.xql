xquery version "3.0";

import module namespace util = "http://exist-db.org/xquery/util";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $view := concat($exist:controller, '/modules/view.xql');
declare variable $methods := ('GET', 'POST', 'HEAD', 'OPTIONS');

(: calculate the xml filename from URL path :)
declare function local:item($type) {
    let $seq := fn:tokenize($exist:path, '/')
    let $file := $seq[fn:last()]
    let $seq2 := fn:tokenize($file, '\.')
    return
        $seq2[1]
};


(: default: everything is passed through :)
declare function local:default() {
    (: don't cache ... bad responses can be cached :)
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="no"/>
    </ignore>
};

(: add a / to a request and redirect :)
declare function local:redirect-with-slash() {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/')}"/>
    </dispatch>
};

(: forward to html page via the view :)
declare function local:dispatch($uri as xs:string) {
    (: if HEAD or OPTIONS don't forward to the templating system :)
    if (request:get-method() = ('OPTIONS', 'HEAD')) then
        (response:set-status-code(200),<empty/>)
    (: otherwise, use the templating system :)
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}{$uri}"/>
            <view><forward url="{$view}"/></view>
        </dispatch>
};

(: forward to html page via the view with attribute :)
declare function local:dispatch-attribute($uri as xs:string, $param as xs:string, $value as xs:string) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$uri}">
            <set-attribute name="{$param}" value="{$value}"/>
        </forward>
        <view>
            <forward url="{$view}"/>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/modules/html/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
     </dispatch>
};

(: serialize some xml file :)
declare function local:serialize-xml($type, $file) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/dashboard/serialize_xml.xql">
            <set-attribute name="{$type}" value="{$file}"/>
        </forward>
    </dispatch>
};

(: serialize a text as a PDF :)
declare function local:serialize-text-pdf($uri, $file) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/mpese-text-pdf.xql">
            <set-attribute name="text" value="{$file}"/>
            <set-attribute name="uri" value="{$uri}"/>
        </forward>
    </dispatch>
};

(: serialize a text as an xml file :)
declare function local:serialize-text-xml($file) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/mpese-text-xml.xql">
            <set-attribute name="text" value="{$file}"/>
        </forward>
    </dispatch>
};

(: serialize a text as an xml file :)
declare function local:serialize-simple-xml($file) {
    let $file_mod := fn:replace($file, '.simple', '')
        return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/mpese-text-simple-xml.xql">
            <set-attribute name="text" value="{$file_mod}"/>
        </forward>
    </dispatch>
};

(: serialize a text as a text file :)
declare function local:serialize-text-txt($file) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/mpese-text-txt.xql">
            <set-attribute name="text" value="{$file}"/>
        </forward>
    </dispatch>
};

(: handle URL to a text:)
declare function local:texts() {
    (: work out name of the file :)
    let $file := fn:concat(local:item('text'), '.xml')
    return
        (: throw a 404 if the file doesn't exist :)
        if (fn:not(fn:doc-available('/db/mpese/tei/corpus/texts/' || $file))) then
            (response:set-status-code(404), local:dispatch('/modules/html/sub404.html'))
        else
            (: simple xml, used for processing with VARD :)
            if (fn:ends-with($exist:path, '.simple.xml')) then
                local:serialize-simple-xml($file)
            (: TEI/XML :)
            else if (fn:ends-with($exist:path, '.xml')) then
                local:serialize-text-xml($file)
            (: we want a PDF :)
            else if (fn:ends-with($exist:path, '.pdf')) then
                local:serialize-text-pdf($exist:path, $file)
            (: a txt file :)
            else if (fn:ends-with($exist:path, '.txt')) then
                local:serialize-text-txt($file)
            (: HTML version of the text :)
            else
                local:dispatch-attribute('/modules/html/text.html', 'text', $file)
};

(: handle URL to a manuscript :)
declare function local:mss() {
    let $file := fn:concat(local:item('mss'), '.xml')
    return
        if (fn:not(fn:doc-available('/db/mpese/tei/corpus/mss/' || $file))) then
            (response:set-status-code(404), local:dispatch('/modules/html/sub404.html'))
        else
            local:dispatch-attribute('/modules/html/mss.html', 'mss', $file)
};

response:set-header("Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self' data:; script-src 'self' 'unsafe-inline' www.googletagmanager.com www.google-analytics.com; img-src 'self' www.google-analytics.com data:; frame-src 'self'"),
response:set-header("X-Content-Type-Options", "nosniff"),
response:set-header("X-Frame-Options", "Deny"),

if (request:get-method() = 'OPTIONS') then
    if (ends-with($exist:path, '.xql')) then
        response:set-header('MPESE', 'GET, POST, HEAD, OPTIONS')
    else
        response:set-header('MPESE', 'GET, HEAD, OPTIONS')
else
    (),

(: are we getting a valid URI? :)
if (not($exist:path castable as xs:anyURI)) then
    (response:set-status-code(400), response:stream((), ''),
    <message>400: Bad URL: {$exist:path}</message>)
(: the app only supports certain methods and POST is only supported in .xql files: ditch undesirable stuff :)
else if (not (request:get-method() = $methods) or (request:get-method() eq 'POST' and not(fn:ends-with($exist:path, '.xql')))) then
    (util:log('INFO', ('Unexpected method ' ||request:get-method() || ' to ' || $exist:path)),
    response:set-status-code(405), response:stream((), ''),
    <message>405: {request:get-method()} is not supported for {$exist:path}</message>)
(: limit the options ... needs nginx to rewrite this though :)
(: empty path :)
else if (fn:starts-with($exist:path, "/resources/")) then
    (response:set-header('Cache-Control', 'public, max-age=3600, must-revalidate'),
    local:default())
else if (fn:starts-with($exist:path, "/modules/")) then
    (response:set-status-code(404), local:dispatch('/modules/html/sub404.html'))
else if ($exist:path eq "") then
    local:redirect-with-slash()
(: homepage, / or /index.html :)
else if ($exist:path eq '/' or $exist:path eq '/index.html') then
    local:dispatch('/modules/html/home.html')
(: handle URL that ends without a slash, eg. /dashboard :)
else if (fn:matches($exist:path, '^[^\.]*[^/]$')) then
    local:redirect-with-slash()
else if (fn:matches($exist:path, '^(/m/)(\w+|%20|%27|-|_)+\.html$')) then
    local:mss()
else if (fn:matches($exist:path, '^(/t/)(\w+|%20|%27|-|_)+\.(html|simple\.xml|xml|pdf|txt)$')) then
    local:texts()
else if (fn:matches($exist:path, '^(/p/)(\w+|%20)+\.html$')) then
    if (fn:empty(doc('/db/mpese/tei/corpus/people/people.xml')/id(local:item('person_id')))) then
        (response:set-status-code(404), local:dispatch('/modules/html/sub404.html'))
    else
        local:dispatch-attribute('/modules/html/person.html', 'person_id', local:item('person_id'))
else if (fn:ends-with($exist:path, ".html")) then
    local:dispatch($exist:path)
else
    (: everything else is passed through :)
    local:default()
