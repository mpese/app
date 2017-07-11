xquery version "3.1";


declare function local:set-message($msg as xs:string, $redirect as xs:anyURI) {
    (session:set-attribute('msg', $msg),
    response:redirect-to($redirect))
};

let $redirect := xs:anyURI('../dashboard/')

let $collection := '/db/word_docs/'

let $filename := request:get-uploaded-file-name('word_file')
(:let $cleaned := fn:replace($filename, '[ ’\(\)]', '') :)

return
    (: check a filename is set :)
    if ($filename eq '') then
        local:set-message('No file provided', $redirect)
    (: bail if it isn't a .docx file :)
    else if (not(fn:ends-with($filename, '.docx'))) then
        local:set-message('No a .docx file', $redirect)
    else
    (: attempt to store the file :)
        let $store := xmldb:store($collection, encode-for-uri($filename),
                request:get-uploaded-file-data('word_file'))
        return
            if (not($store)) then
                local:set-message(fn:concat($filename, ' has not been been stored!'), $redirect)
            else
                local:set-message(fn:concat($filename, ' has been stored'), $redirect)