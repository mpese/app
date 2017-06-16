xquery version "3.0";
declare boundary-space preserve;
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";

declare variable $project_uri := "/db/apps/mpese/data/project.xml";
declare variable $data := doc($project_uri);
declare variable $title := $data/project/title/text();

<html lang="en">
  <head>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="description" content=""/>
    <meta name="author" content="Mike Jones (mike.a.jones@bristol.ac.uk)"/>

    <title>{$title}</title>
    
    <!-- Bootstrap CSS -->
    <link href="resources/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="resources/css/style.css" rel="stylesheet"/>
    <link href="https://maxcdn.bootstrapcdn.com/css/ie10-viewport-bug-workaround.css" rel="stylesheet"/>
  </head>
  <body>
  
    <!-- navigation -->
    <nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <a class="navbar-brand" href="index.html">{$data/project/abbr/text()}<span class="hidden-xs">: {$title}</span></a>
        </div>
      </div>
    </nav>

    <!-- project abstract -->
    <div class="jumbotron">
      <div class="container">
        <p>{$data/project/abstract/node()}</p>
      </div>
    </div>

    <!-- details -->
    <div class="container">
        <div class="row">
            <div class="col-md-12">
                <h2>About the Project</h2>
                <div class="col-md-3">
                    <img src="{$data/project/image/url/text()}" alt="{$data/project/image/description/text()}"/>
                    <p class="mpese-home-img-caption">{$data/project/image/description/text()}<br/>
                    {$data/project/image/copyright/text()}</p>
                </div>
                {$data/project/description/node()}
            </div>
        </div>
        <hr/>
        <div class="row">
            <div class="col-md-12">
                <div>
                 {
                 for $group in $data//people/group
                    return
                        <div class="group" id="{$group/@id}">
                            <h3>{$group/title/text()}</h3>
                            <div class="person">{
                                for $person in $group/members/person
                                    return
                                        <div>
                                            <h4>{$person/title/text()} {$person/name/text()} ({$person/institution/text()}) – {$person/role/text()}</h4>
                                            <p>{$person/bio/node()}</p>
                                        </div>
                               }</div>
                        </div>
                     }
                    </div>
                </div>
        </div>
        <hr/>
      <footer>
      <div class="logo-block">
          <img class="logo" src="resources/img/logo-AHRC.jpg" height="50" alt="AHRC"/>
          <img class="logo" src="resources/img/logo-birmingham.svg" height="50" alt="University of Birmingham"/>
          <img class="logo" src="resources/img/logo-bristol.svg" height="50" alt="University of Bristol"/>
          </div>
        <p>&#169; 2017 University of Birmingham, University of Bristol.</p>
      </footer>
    
    </div> <!-- /container -->


        <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="resources/js/jquery.min.js"></script>
    <script src="resources/js/bootstrap.min.js"></script>
    <!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
    <script src="https://maxcdn.bootstrapcdn.com/js/ie10-viewport-bug-workaround.js"></script>
   </body>
</html>