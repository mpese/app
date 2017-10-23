xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $view := concat($exist:controller, '/modules/view.xql');


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
    (util:log('INFO', ('local:default')),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>)
};

(: add a / to a request and redirect :)
declare function local:redirect-with-slash() {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/')}"/>
    </dispatch>
};

(: forward to html page via the view :)
declare function local:dispatch($uri as xs:string) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$uri}"/>
        <view><forward url="{$view}"/></view>
    </dispatch>
};

(: forward to html page via the view with attribute :)
declare function local:dispatch-attribute($uri as xs:string, $param as xs:string, $value as xs:string) {
    (util:log('INFO', (concat('local:dispatch-attribute', ' ', $uri, ' ', $param, ' ', $value))),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$uri}">
            <set-attribute name="{$param}" value="{$value}"/>
        </forward>
        <view>
            <forward url="{$view}"/>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
     </dispatch>)
};

(: serialize some xml file :)
declare function local:serialize-xml($type, $file) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/dashboard/serialize_xml.xql">
            <set-attribute name="{$type}" value="{$file}"/>
        </forward>
    </dispatch>
};

(: handle dashboard related urls :)
declare function local:dashboard() {
    (: /dashboard/ or /dashboard/index.html :)
    if ($exist:path eq '/dashboard/' or $exist:path eq '/dashboard/index.html') then
        (util:log('INFO', ('Dasboard homepage')),
        local:dispatch('/dashboard/index.html'))
    (: XML file of a text, e.g. /dashboard/text/Baconpeech.xml or /dashboard/text/Bacon%20Speech.xml :)
    else if (fn:starts-with($exist:path , '/dashboard/text/') and fn:ends-with($exist:path, '.xml')) then
        (util:log('INFO', ('Dashboard: text as XML')),
        local:serialize-xml('text', concat(local:item('text'), '.xml')))
    (: HTML file of a text, e.g. /dashboard/text/BaconSpeech.html or /dashboard/text/Bacon%20Speech.html :)
    else if (fn:starts-with($exist:path , '/dashboard/text/') and fn:ends-with($exist:path, '.html')) then
        (util:log('INFO', ('Dashboard: text as HTML')),
        local:dispatch-attribute('/dashboard/text_item.html', 'text', concat(local:item('text'), '.xml')))
    (: /dashboard/mss/all/ or /dashboard/mss/all/index.html :)
    else if ($exist:path eq '/dashboard/mss/all.html') then
        (util:log('INFO', ('Dashboard: display all MSS')),
        local:dispatch('/dashboard/mss_all.html'))
    (: HTML file of a manuscript, e.g. /dashboard/mss/BLAddMS11049.html :)
    else if (fn:matches($exist:path, '(/dashboard/mss/)(\w+|%20)+\.html$')) then
        (util:log('INFO', ('Dashboard: display a MS as HTML')),
        local:dispatch-attribute('/dashboard/mss_item.html', 'mss', concat(local:item('mss'), '.xml')))
    else if (fn:matches($exist:path, '(/dashboard/mss/)(\w+|%20)+\.xml$')) then
        (util:log('INFO', ('Dashboard: mss as XML')),
        local:serialize-xml('mss', concat(local:item('mss'), '.xml')))
    (: list people, /dashboard/people/ /dashboard/people/index.html :)
    else if ($exist:path eq '/dashboard/people/' or $exist:path eq '/dashboard/people/index.html') then
        (util:log('INFO', ('Dashboard: display all people')),
        local:dispatch('/dashboard/people_all.html'))
    else if (fn:matches($exist:path, '/dashboard/people/P[0-9]{4}\.html$')) then
        (util:log('INFO', ('Display a person')),
        local:dispatch-attribute('/dashboard/person.html', 'pid', local:item('pid')))
    else
        (util:log('INFO', ('Dashboard: default handling')),
        local:default())
};

util:log('INFO', ($exist:path)),

(: empty path :)
if ($exist:path eq "") then
    (util:log('INFO', ('Homepage, no slash')),
    local:redirect-with-slash())
(: homepage, / or /index.html :)
else if ($exist:path eq '/' or $exist:path eq '/index.html') then
    (util:log('INFO', ("Hompage, / or /index.html")),
    local:dispatch('/index.html'))
(: handle URL that ends without a slash, eg. /dashboard :)
else if (exists(fn:analyze-string($exist:path, '\/\w+$')//fn:match)) then
    (util:log('INFO', ('URL without trailing slash')),
    local:redirect-with-slash())
(: public: homepage :)
else if ($exist:path eq '/h/' or $exist:path eq '/h/index.html') then
    (util:log('INFO', (' new homepage')),
    local:dispatch('/home.html'))
(: public: text details :)
else if (fn:matches($exist:path, '^(/h/t/)(\w+|%20)+\.html$')) then
    (util:log('INFO', (' new text homepage')),
    local:dispatch-attribute('/text.html', 'text', concat(local:item('text'), '.xml')))
else if (fn:starts-with($exist:path, "/dashboard/")) then
    (: forward dashboard :)
    (util:log('INFO', ('dashboard URL')),
    local:dashboard())
else
    (: everything else is passed through :)
    (util:log('INFO', ('Default handling')),
    local:default())
