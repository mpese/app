xquery version "3.1";

declare option exist:serialize "method=text media-type=text/plain omit-xml-declaration=yes";

if (not(empty(request:get-attribute('text')))) then

    (: uri of the text :)
    let $text := concat('/db/mpese/tei/corpus/texts/', request:get-attribute('text'))

    (: get doc ready for transformation :)
    let $doc := doc($text)

    (: create fop xml :)
    let $xsl := doc('text_to_txt.xsl')
    return transform:transform($doc, $xsl, ())

else
    response:set-status-code(404)
