xquery version "3.1";

import module namespace ui = "http://mpese.rit.bris.ac.uk/ui/" at "../modules/ui.xql";

let $redirect := xs:anyURI('../dashboard/')

let $collection := '/db/word_docs/'

let $filename := request:get-uploaded-file-name('word_file')
(:let $cleaned := fn:replace($filename, '[ ’\(\)]', '') :)

return
    (: check a filename is set :)
    if ($filename eq '') then
        ui:alert-fail('No file provided', $redirect)
    (: bail if it isn't a .docx file :)
    else if (not(fn:ends-with($filename, '.docx'))) then
        ui:alert-fail('No a .docx file', $redirect)
    else
    (: attempt to store the file :)
        let $store := xmldb:store($collection, encode-for-uri($filename),
                request:get-uploaded-file-data('word_file'))
        return
            if (not($store)) then
                ui:alert-fail(fn:concat($filename, ' has not been been stored!'), $redirect)
            else
                ui:alert-success(fn:concat($filename, ' has been stored'), $redirect)