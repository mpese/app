# README

## Environment

The build uses node and npm (https://nodejs.org/en/). Grunt is used for
building and packaging the application. Deployment uses ant tasks (http://ant.apache.org/).
Ensure that node, npm and ant are in your $PATH.

```
git clone git@bitbucket.org:researchit/mpese-app.git
cd mpese-app
npm install
```

```
git clone git@github.com:eXist-db/exist.git exist-src
cd exist-src
sh build.sh
```

To create a .xar file

```
grunt default
```

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