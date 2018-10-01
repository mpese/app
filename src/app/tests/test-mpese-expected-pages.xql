xquery version "3.1";

module namespace test-page = "http://mpese.ac.uk/corpus/pages/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";

declare variable $test-page:host := "http://127.0.0.1:8080/exist/apps/mpese";

(:~
 : Hompage test
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the web application
 : 3) There should be 28 pagination links (14 top, 14 bottom)
 : 4) There should be 20 results
 :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Manuscript Pamphleteering in Early Stuart England')")
%test:assertXPath("count($result//ul[@class='pagination']/li) eq 28")
%test:assertXPath("count($result//div[@class='result-entry']) eq 20")
function test-page:homepage-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/'), false(), ())
};

(:~
 : Hompage test - a search
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the web application (h1)
 : 3) We should see search results titles
 :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Manuscript Pamphleteering in Early Stuart England')")
%test:assertXPath("contains($result/string(), 'Speech at his Death')")
%test:assertXPath("contains($result/string(), 'Separate Catalogues')")
%test:assertXPath("count($result//div[@class='result-entry']) > 0")
function test-page:homepage-search() {
    httpclient:get(xs:anyURI($test-page:host || '/?search=ralegh'), false(), ())
};

(:~
 : A text page
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the text (h1)
 : 3) We should see the MS details (h2)
 :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains(normalize-space($result//h1/string()), 'Speech at his Death')")
%test:assertXPath("contains(normalize-space($result//h2/string()), 'British Library, Additional MS 11600, ff. 21r-22r')")
function test-page:text-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/t/RaleighSpeechDeath1618.html'), false(), ())
};

(:~
 : A manuscript page
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the text (h1)
 :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains(normalize-space($result//h1/string()), 'British Library, Additional MS 11600')")
function test-page:ms-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/m/BLAddMS11600.html'), false(), ())
};

(:~
 : A advanced search page
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
 :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Advanced search')")
function test-page:advanced-search-page-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/advanced.html'), false(), ())
};

(:~
 : A advanced search results (results with transcripts and images)
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
 : 3) There should be 28 pagination links (14 top, 14 bottom)
 : 4) There should be 20 results
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Manuscript Pamphleteering in Early Stuart England')")
%test:assertXPath("count($result//ul[@class='pagination']/li) > 0")
%test:assertXPath("count($result//div[@class='result-entry']) eq 20")
function test-page:advanced-search-page-results-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/results.html?image=yes&amp;transcript=yes'), false(), ())
};

(:~
 : Introduction page
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Introduction')")
function test-page:introduction-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/introduction.html'), false(), ())
};

(:~
 : Scope page
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Scope')")
function test-page:scope-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/scope.html'), false(), ())
};

(:~
 : Scope page
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Transcription Conventions')")
function test-page:conventions-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/conventions.html'), false(), ())
};

(:~
 : Collation page
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Collation Sets')")
function test-page:collations-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/collation.html'), false(), ())
};

(:~
 : Technical details
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Technical Details')")
function test-page:technical-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/technical.html'), false(), ())
};

(:~
 : Teaching
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Teaching')")
function test-page:teaching-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/teaching.html'), false(), ())
};

(:~
 : About the project
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'About the Project')")
function test-page:about-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/about.html'), false(), ())
};

(:~
 : Copyright
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Copyright and licence')")
function test-page:copyright-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/copyright.html'), false(), ())
};

(:~
 : Cookies
 :
 : 1) We should get a 200 response
 : 2) We should see the name of the page
:)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("contains($result//h1/string(), 'Cookies and Privacy Policy')")
function test-page:cookies-ok() {
    httpclient:get(xs:anyURI($test-page:host || '/cookies.html'), false(), ())
};