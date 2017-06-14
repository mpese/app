module.exports = function (grunt) {
    
    grunt.initConfig({

        pkg: grunt.file.readJSON('package.json'),

        app: {
            name: 'mpese'
        },

        clean: {
            clean: ['dist']
        },

        copy: {
            dist: {
                files: [
                    {
                        expand: true,
                        cwd: './',
                        src: ['resources/**', '*.xql', '*.xml', '*.html'],
                        dest: 'dist/'
                    }
                ]
            }
        },

        zip: {
            xar: {
                cwd: 'dist/',
                src: ['dist/**'],
                dest: 'build/mpese.xar'
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