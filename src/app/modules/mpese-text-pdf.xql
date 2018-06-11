xquery version "3.1";

if (not(empty(request:get-attribute('text')))) then

    (: uri of the text :)
    let $text := concat('/db/mpese/tei/corpus/texts/', request:get-attribute('text'))

    (: get doc ready for transformation :)
    let $doc := doc($text)

    (: add original URL as a parameter :)
    let $uri := 'https://mpese.ac.uk' || replace(request:get-attribute('uri'), '.pdf', '.html')
    let $params := <parameters><param name="url" value="{$uri}"/></parameters>

    (: create fop xml :)
    let $xsl := doc('xsl/text_to_pdf.xsl')
    let $output-doc := transform:transform($doc, $xsl, $params)
    let $media-type as xs:string := 'application/pdf'

    (: return the pdf :)
    return
        response:stream-binary(
                xslfo:render($output-doc, $media-type, ()),
                $media-type, ()
        )
else
    response:set-status-code(404)
