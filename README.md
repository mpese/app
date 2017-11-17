# README

This is the MPESE web application that is deployed on the eXist platform. This README provides details
on building and deploying the application.

## Environment

The build and deployment uses ant tasks (http://ant.apache.org/).
Ensure that ant (and Java) are in your $PATH.

Get the mpese app source code:

```
git clone git@bitbucket.org:researchit/mpese-app.git
cd mpese-app
```

Get eXist and build the platform. This gives us the jar files needed for the Ant tasks:

```
git clone git@github.com:eXist-db/exist.git exist-src
cd exist-src
sh build.sh
```

Update the build.properties to point to the eXist directory:

```
server.dir=/Users/mikejones/Development/workspaces/mpese/exist-src
```

To deploy the .xar file

```
ant deploy
```

The ant task takes the version number from version.properties file and adds it to the repo.xml and expath-pkg.xml. It also adds the .xar name (including) to the deploy.xql.

The ant task uses the deploy.xql file to save the .xar file to the database in the xar_files collection, remove the previously deployed .xar and install this new version.

## App version

We need to manually update the values in version.properties