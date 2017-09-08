xquery version "3.1";

import module namespace ui = "http://mpese.rit.bris.ac.uk/ui/" at '../modules/ui.xql';
import module namespace dashboard = "http://mpese.rit.bris.ac.uk/dashboard/" at '../modules/dashboard.xqm';

let $redirect := xs:anyURI('../dashboard/')
let $param_name := 'word_file'

return
    let $msg := dashboard:store_word_doc($param_name)
    return
        (ui:alert($msg), response:redirect-to($redirect))