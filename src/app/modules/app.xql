xquery version "3.1";

module namespace app = "http://mpese.rit.bris.ac.uk/templates";

import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace config = "http://mpese.rit.bris.ac.uk/config" at "config.xqm";

declare boundary-space preserve;

(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute data-template="app:test" 
 : or class="app:test" (deprecated). The function has to take at least 2 default
 : parameters. Additional parameters will be mapped to matching request or session parameters.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the data-template attribute <code>data-template="app:test"</code>.</p>
};

declare function app:title($node as node(), $model as map(*)) {
    $config:repo-descriptor//repo:version/text()
};

declare function app:version($node as node(), $model as map(*)) {
    $config:repo-descriptor//repo:version/text()
};

declare function app:deployed($node as node(), $model as map(*)) {
    format-dateTime(xs:dateTime($config:repo-descriptor//repo:deployed/text()), "[D01]/[M01]/[Y0001]")
};

declare function app:abstract($node as node(), $model as map(*)) {
    <p>{$config:project/abstract/node()}</p>
};

declare function app:description($node as node(), $model as map(*)) {
    <p>{$config:project/description/node()}</p>
};

declare function app:image($node as node(), $model as map(*)) {
    <div>
        <img class="mpese-home-img-caption" src="{$config:project/image/url/text()}" alt="{$config:project/image/description/text()}"/>
        <p class="mpese-home-img-caption">{$config:project/image/description/text()}<br/>
            {$config:project/image/copyright/text()}</p>
    </div>
};

declare function app:people($node as node(), $model as map(*)) {
    <div>
        {
            for $group in $config:project//people/group[@id = 'project_team']
            return
                <div class="group" id="{$group/@id}">
                    <h3>{$group/title/text()}</h3>
                    <div class="person">{
                        for $person in $group/members/person
                        return
                            <div>
                                <h4>{$person/name/text()} ({$person/institution/text()}) – {$person/role/text()}</h4>
                                <p>{$person/bio/node()}</p>
                            </div>
                    }</div>
                </div>
        }
    </div>
};

declare function app:advisory($node as node(), $model as map(*)) {
    <div>
        {
            for $group in $config:project//people/group[@id = 'committee' or @id = 'board']
            return
                <div class="group" id="{$group/@id}">
                    <h3>{$group/title/text()}</h3>
                    <ul class="list-unstyled">{
                        for $person in $group/members/person
                        return
                            <li>
                                {$person/title/text()} {$person/name/text()} ({$person/institution/text()})
                            </li>
                    }</ul>
                </div>
        }
    </div>
};

