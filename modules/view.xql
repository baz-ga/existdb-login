(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates";

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace config="http://baz-ga.de/bazga-webapp/config" at "config.xqm";
import module namespace app="http://baz-ga.de/bazga-webapp/templates" at "app.xql";
import module namespace search="http://baz-ga.de/bazga-webapp/search" at "search.xqm";
import module namespace sitemap="http://baz-ga.de/bazga-webapp/sitemap" at "sitemap.xqm";
import module namespace app-shared="http://xquery.weber-gesamtausgabe.de/modules/app-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/app-shared.xqm";
import module namespace i18n="http://baz-ga.de/bazga-webapp/i18n" at "i18n.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
}
(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
let $content := request:get-data()
return
    templates:apply($content, $lookup, (), $config)