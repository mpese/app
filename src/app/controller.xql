xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $view := concat($exist:controller, '/modules/view.xql');

(: calculate the xml filename from URL path :)
declare function local:item_file($type) {
    let $seq := fn:tokenize($exist:path, '/')
    let $idx := fn:index-of($seq, $type) + 1
    return
        fn:concat($seq[$idx], '.xml')
};

util:log('INFO', ($exist:path)),

if ($exist:path eq "") then
    <dispatch
        xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect
            url="{concat(request:get-uri(), '/')}"/>
    </dispatch>
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
else if ($exist:path eq "/dashboard") then
    (: forward dashboard :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/index.html')}"/>
    </dispatch>
else if ($exist:path eq "/dashboard/") then
    (: forward dashboard :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), 'index.html')}"/>
    </dispatch>
else if (fn:starts-with($exist:path, "/dashboard/text/")) then
    if (ends-with($exist:resource, ".xml")) then
        let $file := local:item_file('text')
        return
            (util:log('INFO', (fn:concat('Dashboard text URL, looking for ', $file))),
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/dashboard/serialize_xml.xql">
                    <set-attribute name="text" value="{$file}"/>
                </forward>
            </dispatch>)
    else
        let $file := local:item_file('text')
        return
            (util:log('INFO', (fn:concat('Dashboard text URL, looking for ', $file))),
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/dashboard/text_item.html">
                    <set-attribute name="text" value="{$file}"/>
                </forward>
                <view>
                    <forward url="{$view}"/>
                </view>
            </dispatch>)
else if (fn:starts-with($exist:path, "/dashboard/mss/")) then
    if ($exist:path eq "/dashboard/mss/all/index.html") then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/dashboard/mss_all.html"/>
            <view>
                <forward url="{$view}"/>
            </view>
        </dispatch>
    else
        let $file := local:item_file('mss')
        return
        (util:log('INFO', (fn:concat('Dashboard mss URL, looking for ', $file))),
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/dashboard/mss_item.html">
                    <set-attribute name="mss" value="{$file}"/>
                </forward>
                <view>
                    <forward url="{$view}"/>
                </view>
            </dispatch>)
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    (util:log('INFO', $exist:resource)
    ,
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html"method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
    )
    (: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else
    (: everything else is passed through :)
    (util:log('INFO', ('Here ...')),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>)
