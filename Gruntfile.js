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
                        src: ['!**/*.bak', 'resources/**', 'modules/**', 'data/**', '*.xql', '*.xml', '*.html'],
                        dest: './build/'
                    }
                ]
            }
        },

        zip: {
            xar: {
                cwd: './build/',
                src: ['build/**'],
                dest: 'dist/mpese.xar'
            }
        }

    });

    // clean
    grunt.loadNpmTasks('grunt-contrib-clean');

    // copy our files into place
    grunt.loadNpmTasks('grunt-contrib-copy');

    // zip
    grunt.loadNpmTasks('grunt-zip');

    // default task
    grunt.registerTask('default', ['clean', 'copy', 'zip'])
}
