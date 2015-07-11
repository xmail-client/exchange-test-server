'use strict';

var gulp   = require('gulp');
var plugins = require('gulp-load-plugins')();
var CI = process.env.CI === 'true';

var paths = {
  coffee: ['./lib/**/*.coffee'],
  watch: ['./gulpfile.js', './lib/**', './spec/**', '!spec/{temp,temp/**}'],
  tests: ['./spec/**/*.coffee', '!spec/{temp,temp/**}']
};

var plumberConf = {};

if (process.env.CI) {
  plumberConf.errorHandler = function(err) {
    throw err;
  };
}

gulp.task('lint', function () {
  return gulp.src(paths.coffee)
    .pipe(plugins.coffeelint())
    .pipe(plugins.coffeelint.reporter());
});

gulp.task('unitTest', function () {
  require('coffee-script/register')
  gulp.src(paths.tests, {cwd: __dirname})
    .pipe(plugins.plumber(plumberConf))
    .pipe(plugins.mocha({ reporter: 'spec' }));
});

gulp.task('watch', ['test'], function () {
  gulp.watch(paths.watch, ['test']);
});

gulp.task('test', ['lint', 'unitTest']);

gulp.task('dist', function () {
  return gulp.src(paths.coffee, {base: './lib'})
    .pipe(plugins.coffee({bare: true}))
    .pipe(gulp.dest('./dist'));
});

gulp.task('default', ['test', 'dist']);
