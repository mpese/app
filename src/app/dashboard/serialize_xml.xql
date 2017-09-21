xquery version "3.1";

(: quick implementation to demo xincludes being expanded :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "xml";
declare option output:media-type "application/xml";
declare option exist:serialize "expand-xincludes=yes";

let $file := request:get-attribute('text')
return
    doc(concat('/db/mpese/tei/corpus/texts/', $file))