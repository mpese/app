xquery version "3.1";

if (not(empty(request:get-attribute('text')))) then

    let $text := concat('/db/mpese/tei/corpus/texts/', request:get-attribute('text'))
    let $doc := doc($text)
    let $uri := 'https://mpese.ac.uk' || replace(request:get-attribute('uri'), '.pdf', '.html')
    let $params := <parameters><param name="url" value="{$uri}"/></parameters>
    let $xsl := doc('text_to_pdf.xsl')
    let $output-doc := transform:transform($doc, $xsl, $params)
    let $media-type as xs:string := 'application/pdf'
    return
        response:stream-binary(
                xslfo:render($output-doc, $media-type, ()),
                $media-type, ()
        )
else
    response:set-status-code(404)
