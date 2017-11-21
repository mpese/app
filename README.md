# README

This is the MPESE web application that is deployed on the eXist
platform. This README provides details on building and deploying the
application.

## Environment

The build and deployment uses Apache Ant tasks (http://ant.apache.org/)
and Apache Ivy (http://ant.apache.org/ivy/). Ensure that ant (and Java)
are in your $PATH. Ivy is installed via Ant.

For development, we are using eXist, proxied by NGINX running on
Vagrant, which listens on 8000 (NGINX) and 9090 (eXist):

https://bitbucket.org/researchit/mpese-exist-vagrant


## Building and deploying

Get the mpese app source code:

```
git clone git@bitbucket.org:researchit/mpese-app.git
cd mpese-app
```

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