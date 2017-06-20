# README

## Environment

The build uses node and npm (https://nodejs.org/en/). Grunt is used for
building and packaging the application. Deployment uses ant tasks (http://ant.apache.org/).
Ensure that node, npm and ant (and Java) are in your $PATH.

Get the mpese app source code and instal the npm packages:

```
git clone git@bitbucket.org:researchit/mpese-app.git
cd mpese-app
npm install
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

To create a .xar file:

```
grunt default
```

The grunt task takes the version number from package.json file and adds it to the repo.xml and expath-pkg.xml. It also adds the .xar name (including) to the deploy.xql.

To deploy the .xar file

```
ant deploy
```

The ant task uses the deploy.xql file to save the .xar file to the database in the xar_files collection, remove the previously deployed .xar and install this new version.

## App versioning

The grunt file takes the version number from package.json file. We can
change the version via the npm version command. https://docs.npmjs.com/cli/version

For a very minor version change:

```
npm version patch
```

For a minor change:

```
npm version minor
```

For a major change:

```
npm version minor
```