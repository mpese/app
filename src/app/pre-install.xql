xquery version "1.0";

(
(: the root collection :)
xmldb:create-collection('/db', 'mpese'),

(: tei xml :)
xmldb:create-collection('/db/mpese', 'tei'),

(: word upload workspace :)
xmldb:create-collection('/db/mpese', 'word'),

(: docx storage  :)
xmldb:create-collection('/db/mpese/word', 'docx'),

(: docx unzipped  :)
xmldb:create-collection('/db/mpese/word', 'unzip')
)