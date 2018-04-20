xquery version "3.1";


let $text := doc('/db/mpese/tei/corpus/texts/RaleighSpeechDeath1618.xml')
let $xsl := doc('modules/text_to_pdf.xsl')
let $output-doc := transform:transform($text, $xsl, ())
let $media-type as xs:string := 'application/pdf'

return
    $output-doc
