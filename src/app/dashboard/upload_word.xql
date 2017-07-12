xquery version "3.1";

import module namespace dashboard = "http://mpese.rit.bris.ac.uk/dashboard/" at '../modules/dashboard.xql';

let $redirect := xs:anyURI('../dashboard/')
let $param_name := 'word_file'

return
    dashboard:store_word_doc($param_name, $redirect)
