xquery version "3.1";

module namespace test-access = "http://mpese.ac.uk/corpus/http/test/";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";

declare variable $test-access:host := "http://127.0.0.1:8080/exist/apps/mpese";

(:-- tests against the homepage ---:)

(: HEAD returns 200 :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'") function test-access:head-ok() {
    httpclient:head(xs:anyURI($test-access:host || '/'), false(), ())
};

(: GET returns 200 :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'") function test-access:get-ok() {
    httpclient:get(xs:anyURI($test-access:host || '/'), false(), ())
};

(: OPTIONS returns 200 and correct methods :)
(: The app 'Allow' header is called 'MPESE' - nginx will change 'MPESE' to 'Allow' on the way out :)
declare %test:assertXPath("$result//@statusCode/string() eq '200'")
%test:assertXPath("$result//*:header[@name='MPESE']/@value/string() eq 'GET, HEAD, OPTIONS'")
function test-access:options-ok() {
    httpclient:options(xs:anyURI($test-access:host || '/'), false(), ())
};

(: PUT returns 405 :)
declare %test:assertXPath("$result//@statusCode/string() eq '405'") function test-access:put-405() {
    httpclient:put(xs:anyURI($test-access:host || '/'), <foo>foo</foo>, false(), ())
};

(: POST returns 405 :)
declare %test:assertXPath("$result//@statusCode/string() eq '405'") function test-access:post-405() {
    httpclient:post(xs:anyURI($test-access:host || '/'), <foo>foo</foo>, false(), ())
};

(: DELETE returns 405 :)
declare %test:assertXPath("$result//@statusCode/string() eq '405'") function test-access:delete-405() {
    httpclient:delete(xs:anyURI($test-access:host || '/'), false(), ())
};