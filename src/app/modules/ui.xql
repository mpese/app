xquery version "3.1";

module namespace ui = "http://mpese.rit.bris.ac.uk/ui/";

import module namespace session = "http://exist-db.org/xquery/session";

(: add the message to the session and redirect :)
declare function ui:alert($msg as node()) {
    let $out := if ($msg/@type eq 'warn') then concat('fail:', $msg/text())
    else concat('success:', $msg/text())
    return
        session:set-attribute('msg', $out)
};

(: if we have an alert then display it :)
declare function ui:msg($node as node(), $model as map(*)) {

    let $msg := (session:get-attribute('msg'), session:remove-attribute('msg'))

    let $type := if (fn:starts-with($msg, 'success:')) then
        'alert-success'
    else
        'alert-danger'

    return
        if (not (empty($msg))) then
            <div class="mpese-alert alert {$type}">{fn:substring-after($msg, ':')}</div>
        else
            ""
};