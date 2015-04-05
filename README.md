# runtime-config

[![NPM Version][npm-image]](https://npmjs.org/package/runtime-config)
[![Build Status][travis-image]](https://travis-ci.org/keis/runtime-config)
[![Coverage Status][coveralls-image]](https://coveralls.io/r/keis/runtime-config?branch=master)

This module attempts to provide a sane subset of the `runtime.json`
functionality that used to be found in `config` but that is now deprecated.

in particular

* only watched attributes are allowed to be changed
* does not support modifying the configuration from within the app
* only one code path to access values the `watch` style


[npm-image]: https://img.shields.io/npm/v/runtime-config.svg?style=flat
[travis-image]: https://img.shields.io/travis/keis/runtime-config.svg?style=flat
[coveralls-image]: https://img.shields.io/coveralls/keis/runtime-config.svg?style=flat
