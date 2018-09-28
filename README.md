# MPESE application

This is the _Manuscript Pamphleteering in Early Stuart England_ (MPESE) 
web application that is deployed on the eXist platform. This README 
provides details on building and deploying the application. 

Any queries can be emailed to research-it@bristol.ac.uk

## Environment

The build and deployment uses Apache Ant tasks (http://ant.apache.org/)
and Apache Ivy (http://ant.apache.org/ivy/). Ensure that ant (and Java)
are in your $PATH. Ivy is installed via Ant.

For development, we are using eXist, proxied by NGINX running on
Vagrant, which listens on 8000 (NGINX) and 9090 (eXist):

## Setup the database platform

See https://github.com/mpese/vagrant-exist

## Get the source code

Get the mpese app source code:

```
git clone git@github.com:mpese/app.git mpese-app
cd mpese-app
```

## Update the build.properties

Create a build.properties file ...

```
cp build.properties.copy build.properties

```

... and optionally add the password of the admin user.

## Populate the database

Populate the database with data and indices:

```
ant setup-data
```

## Deploy the application

To deploy the .xar file

```
ant deploy
```

The ant task takes the version number from version.properties file and
adds it to the repo.xml and expath-pkg.xml. It also adds the .xar name
(including) to the deploy.xql.

The ant task uses the deploy.xql file to save the .xar file to the
database in the xar_files collection, remove the previously deployed
.xar and install this new version.

The dist folder will also include a deploy.xql and undeploy.xql
that can be used on demo and production via the web start admin tool.

## App version

We need to manually update the values in version.properties

## Ant Tasks

The ant build file supports a number of tasks for deploying the app and data
extraction. These are the key deployment tasks:

| Task         | Description                                                       |
---------------|-------------------------------------------------------------------|
| clean        | Remove any build or distribution directories                      |
| dist         | Create a xar file of the application and setup deployment scripts |                                          |
| deploy       | Deploy the application on eXist                                   |

There are also a number of data related tasks:

| Task               | Description                                                       |
---------------------|-------------------------------------------------------------------|
| create-witness-list| For each text, scan MSS for witnesses and update text with list   |
| create-ms-label    | For each text follow xi:includes to create a label                |
| normalize-texts    | Use VARD 2 to create normalized (modern spelling) of texts        |
| extract-data       | Extract all XML for texts, manuscripts and people                 |



## Ant build.properties

Properties might need to be updated.

| Property        | Description                                                          |
|-----------------|----------------------------------------------------------------------|
| xmlrpc          | The xmlrpc endpoint, e.g. xmldb:exist://localhost:9090/exist/xmlrpc  |
| test.url        | The URL for the test suite, e,g.http://localhost:8000/tests/suite.xql|
| username        | Admin username                                                       |
| password        | Can leave blank and will be prompted by ant                          |
| server.base.url | Base URL, e.g. http://localhost:8000/                                |
| vard.home       | Location of VARD2 installation /home/foobar/VARD2.5.4/               |
| google.analytics| Google analytics token                                               |
| extract.dir     | Location to extract data from eXist, e.g.=/home/foobar/mpese-data/   |




