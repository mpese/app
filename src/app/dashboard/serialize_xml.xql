xquery version "3.1";

(: quick implementation to demo xincludes being expanded :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "xml";
declare option output:media-type "application/xml";
declare option exist:serialize "expand-xincludes=yes";

if (not(empty(request:get-attribute('text')))) then
    (util:log('INFO', ('Getting text as xml')),
     util:log('INFO', (request:get-attribute('text'))),
    doc(concat('/db/mpese/tei/corpus/texts/', request:get-attribute('text'))))
else if (not(empty(request:get-attribute('mss')))) then
    (util:log('INFO', ('Getting mss as xml')),
     util:log('INFO', concat('/db/mpese/tei/corpus/mss/', request:get-attribute('mss'))),
    doc(concat('/db/mpese/tei/corpus/mss/', request:get-attribute('mss'))))
else
    response:set-status-code(404)
