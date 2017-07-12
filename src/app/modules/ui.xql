xquery version "3.1";

module namespace ui = "http://mpese.rit.bris.ac.uk/ui/";

import module namespace session = "http://exist-db.org/xquery/session";

(: prefix for successful alerts :)
declare function ui:alert-success($msg as xs:string, $redirect as xs:anyURI) {
    ui:alert(concat('success:', $msg), $redirect)
};

(: prefix for warning alerts :)
declare function ui:alert-fail($msg as xs:string, $redirect as xs:anyURI) {
    ui:alert(concat('fail:', $msg), $redirect)
};

(: add the message to the session and redirect :)
declare function ui:alert($msg as xs:string, $redirect as xs:anyURI) {
    (session:set-attribute('msg', $msg),
    response:redirect-to($redirect))
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
            <div class="alert {$type}">{fn:substring-after($msg, ':')}</div>
        else
            ""
};