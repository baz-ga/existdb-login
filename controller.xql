xquery version "3.1";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace apputil="http://exist-db.org/xquery/apps";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;
declare variable $exist:context external;

declare variable $origin := request:get-attribute('origin');
(:declare variable $origin := request:get-parameter('orgin', '/exist/apps/bazga-webapp/');:)

console:log("controller path: " || $exist:path),
if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
else if (contains($exist:path, "$resources/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{apputil:resolve("http://baz-ga.de/bazga-webapp")}/resources/{substring-after($exist:path, '$resources/')}">
            <set-header name="Cache-Control" value="max-age=1, must-revalidate"/>
        </forward>
        <cache-control cache="no"/>
    </dispatch>
else if ($exist:path = "/") then(
    console:log("matched '/'" || $exist:path),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="login.html"/>
    </dispatch>
)
(:
    restricted.html is secured by the following rules
:)
else if (matches($exist:path, "\?")) then (
        (: login:set-user creates a authenticated session for a user :)
        login:set-user("org.exist.login", (), true()),

        (:
        the login:set-user function internally sets the following request attribute. If this is set we have a logged in
        user.
        :)
        let $user := request:get-attribute("org.exist.login.user")

        (: when the request comes in with a user request param the request was sent by a login form :)
        let $userParam := request:get-parameter("user","")

        (: in case of a logout we get a request param 'logout' :)
        let $logout := request:get-parameter("logout",())
        (:let $result := if (not($userParam != data($user))) then "true" else "false":)

        return
            (:
            when we get a logout the user is redirected to the index.html page in this example. The redirect target
            can be changed to application needs. E.g. redirecting to restricted.html here would pop up the login page
            again as the user is not logged in any more.
            :)
            if($logout = "true") then(
                (:
                When there is a logout request parameter we send the user back to the unrestricted page.
                :)
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="index.html"/>
                </dispatch>
            )
            else if ($user and 'bazga-testers' = sm:get-user-groups($user)) then
                (:
                successful login. The user has authenticated and is in the 'bazga-testers' group. It's important however to keep
                the cache-control set to 'cache="no"'. Otherwise re-authentication after a logout won't be forced. The
                page will get served from cache and not hit the controller any more.
                :)
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <cache-control cache="no"/>
                </dispatch>
            else if(not(string($userParam) eq string($user))) then
                (:
                if a user was send as request param 'user'
                AND it is NOT the same as $user
                a former login attempt has failed.

                Here a duplicate of the login.html is used. This is certainly not the most elegant solution. Just here
                to not complicate things further with templating etc.
                :)
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="fail.html"/>
                </dispatch>

            else
                let $bazga-url := apputil:link-to-app("http://baz-ga.de/bazga-webapp", 'index.html')
                return
                (: if nothing of the above matched we got a login attempt. :)
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="login-templating.html?origin={$origin}">
                        <add-parameter name="origin" value="{$origin}"/>
                        <set-attribute name="$exist:root" value="{$exist:root}"/>
                        <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                        <set-attribute name="$exist:controller" value="{$exist:controller}"/>
                    </forward>
                    <view>
                        <forward url="/{apputil:link-to-app("http://baz-ga.de/bazga-webapp", 'modules/view.xql')}"/>
                    </view>
                    <error-handler>
                        <forward url="{request:get-context-path()}/{$bazga-url}/templates/error-page.html" method="get"/>
                        <forward url="{$bazga-url}/modules/view.xql"/>
                    </error-handler>
                    <cache-control cache="no"/>
                </dispatch>


)else
    (: if nothing of the above matched we got a login attempt. :)
    let $bazga-url := apputil:link-to-app("http://baz-ga.de/bazga-webapp", 'index.html')
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="login-templating.html?origin={$origin}">
            <add-parameter name="origin" value="{$origin}"/>
            <set-attribute name="origin" value="{$origin}"/>
        </forward>
        <view>
            <forward url="/{apputil:resolve("http://baz-ga.de/bazga-webapp")}/modules/view.xql"/>
        </view>
        <error-handler>
            <forward url="{request:get-context-path()}/{$bazga-url}/templates/error-page.html" method="get"/>
            <forward url="{$bazga-url}/modules/view.xql"/>
        </error-handler>
        <cache-control cache="no"/>
    </dispatch>
