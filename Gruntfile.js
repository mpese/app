module.exports = function (grunt) {
    
    grunt.initConfig({

        pkg: grunt.file.readJSON('package.json'),

        app: {
            name: 'mpese'
        },

        clean: {
            clean: ['build', 'dist']
        },

        copy: {
            build: {
                files: [
                    {
                        expand: true,
                        cwd: './src/app',
                        src: ['!**/*.bak', 'resources/**', 'modules/**', 'templates/**', 'data/**', '*.xql', '*.xml', '*.html'],
                        dest: './build/'
                    }
                ]
            }
        },

        replace: {
            pkg: {
                src: [ 'src/app/expath-pkg.xml'],
                dest: 'build/expath-pkg.xml',
                replacements: [
                    {
                        from: '@APPVERSION@',
                        to: '<%= pkg.version %>'
                    }
                ],
            },

            repo: {
                src: [ 'src/app/repo.xml'],
                dest: 'build/repo.xml',
                replacements: [
                    {
                        from: '@APPVERSION@',
                        to: '<%= pkg.version %>'
                    }
                ],
            },

            undeploy: {
                src: [ 'src/deploy/undeploy.xql'],
                dest: 'dist/undeploy.xql',
                replacements: [
                    {
                        from: '@APPVERSION@',
                        to: '<%= pkg.version %>'
                    }
                ],
            },

            deploy: {
                src: [ 'src/deploy/deploy.xql'],
                dest: 'dist/deploy.xql',
                replacements: [
                    {
                        from: '@APPVERSION@',
                        to: '<%= pkg.version %>'
                    }
                ],
            }
        },

        zip: {
            xar: {
                cwd: './build/',
                src: ['build/**'],
                dest: 'dist/<%= pkg.name %>-<%= pkg.version %>.xar'
            }
        }

    });

    // clean
    grunt.loadNpmTasks('grunt-contrib-clean');

    // copy our files into place
    grunt.loadNpmTasks('grunt-contrib-copy');

    // replace version numbers
    grunt.loadNpmTasks('grunt-text-replace');

    // zip
    grunt.loadNpmTasks('grunt-zip');

    // default task
    grunt.registerTask('default', ['clean', 'copy', 'replace', 'zip'])
}
