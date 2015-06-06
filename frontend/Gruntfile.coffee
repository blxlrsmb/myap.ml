module.exports = (grunt) ->
  'use strict'
  #############
  # plugins
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-connect'

  grunt.registerMultiTask 'template', ->
    for file in @files
      src=file.src[0]
      dest=file.dest
      cont=grunt.template.process grunt.file.read(src, encoding: 'utf-8')
      cont=cont.replace(/\r\n/g, '\n')
      grunt.file.write(dest, cont, encoding: 'utf-8')

  ############
  # main
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    stylus:
      compile:
        options:
          urlfunc: 'embedurl'
          compress: false
          "include css": true
        files: [
          {
            expand: true
            cwd: 'src/stylus/'
            src: ['**/*.styl', '!**/_*.styl']
            dest: 'build/css/'
            ext: '.css'
          }
        ]
    jade:
      compile:
        options:
          pretty: true
        files: [
          {
            expand: true
            cwd: 'src/jade/'
            src: '*.jade'
            dest: 'build/'
            ext: '.html'
          }
        ]
    coffee:
      compile:
        options:
          runtime: 'inline'
        files: [
          {
            expand: true
            cwd: 'src/coffee/'
            src: '**/*.coffee'
            dest: 'build/js/'
            ext: '.js'
          }
        ]
    uglify:
      dist:
        files:
          'build/js/main.min.js': ['build/js/main.js']
    copy:
      asset:
        files: [
          {
            expand: true
            cwd: 'src/asset/'
            src: '**/*'
            dest: 'build/'
          }
        ]
      bower:
        files: [
          {
            expand: true
            cwd: 'bower_components/'
            src: '**/*'
            dest: 'build/bower_components/'
          }
        ]
    watch:
      options:
        spawn: false
      asset:
        files: ['src/asset/**/*', 'bower_components/**/*']
        tasks: ['copy:asset']
      coffee:
        files: ['src/coffee/**/*']
        tasks: ['coffee']
      jade:
        files: ['src/jade/**/*']
        tasks: ['jade']
      css:
        files: ['src/stylus/**/*']
        tasks: ['stylus']
    connect:
      server:
        options:
          port: 3000
          base: 'build'
          hostname: '*'
    clean:
      files: ['build', 'tmp', 'dist']

  grunt.registerTask 'default', [
    'stylus:compile'
    'coffee:compile'
    'jade:compile'
    'copy:asset'
    'copy:bower'
    #'uglify:dist'
  ]
  grunt.registerTask 'dev', [
    'default'
    'connect'
    'watch'
  ]
