sinon = require 'sinon'
rewire = require 'rewire'

chain = (funs) ->
  ->
    funs.shift().apply null, arguments

describe "Config", ->
  Config = rewire '../../lib/runtime-config'
  Config.__set__ 'readJson', ->

  config = null
  callback = null
  unexpected = null

  beforeEach ->
    config = new Config path: 'test/data/runtime.json',
      foo: 10
      arr: [1..3]
      nil: null
      bar:
        baz: 'test'
    callback = sinon.stub()
    unexpected = config._unexpected = sinon.stub()

  afterEach ->
    config.watcher.close()

  describe "watch", ->
    it "calls watcher with value from base", (done) ->
      config.watch 'foo', callback
      process.nextTick ->
        assert.calledOnce callback
        assert.calledWith callback, undefined, 10
        done()

    it "calls watcher with deep value from base", (done) ->
      config.watch 'bar.baz', callback
      process.nextTick ->
        assert.calledOnce callback
        assert.calledWith callback, undefined, 'test'
        done()

    # Document current behaivour not sure if this is how it should work
    it "calls watcher with undefined for missing value", (done) ->
      config.watch 'bar.bar', callback
      process.nextTick ->
        assert.calledOnce callback
        assert.calledWith callback, undefined, undefined
        done()

    it "calls watcher with undefined for missing parent value", (done) ->
      config.watch 'baz.baz', callback
      process.nextTick ->
        assert.calledOnce callback
        assert.calledWith callback, undefined, undefined
        done()

  describe "update", ->
    it "calls watcher with updated value", (done) ->
      config.watch 'foo', callback

      process.nextTick ->
        config._update null,
          foo: 20

        assert.calledTwice callback
        assert.calledWith callback, undefined, 10
        assert.calledWith callback, 10, 20
        assert.notCalled unexpected
        done()

    it "calls watcher with updated array", (done) ->
      config.watch 'arr', callback

      process.nextTick ->
        config._update null,
          arr: [1..4]

        assert.calledTwice callback
        assert.calledWith callback, undefined, [1..3]
        assert.calledWith callback, [1..3], [1..4]
        assert.notCalled unexpected
        done()

    it "calls watcher with new value", (done) ->
      config.watch 'baz', callback

      process.nextTick ->
        config._update null,
          baz: 50

        assert.calledTwice callback
        assert.calledWith callback, undefined, undefined
        assert.calledWith callback, undefined, 50
        assert.notCalled unexpected
        done()

    it "calls watcher with base value when deleted", (done) ->
      config.watch 'foo', callback

      process.nextTick ->
        config._update null,
          foo: 50

        assert.calledTwice callback

        process.nextTick ->
          config._update null, {}

          assert.calledThrice callback
          assert.calledWith callback, 50, 10
          assert.notCalled unexpected
          done()

    it "calls watcher with updated deep value", (done) ->
      config.watch 'bar.baz', callback

      process.nextTick ->
        config._update null,
          bar:
            baz: 'other'

        assert.calledTwice callback
        assert.calledWith callback, undefined, 'test'
        assert.calledWith callback, 'test', 'other'
        assert.notCalled unexpected
        done()

    it "calls watcher with new deep value", (done) ->
      config.watch 'nil.nil', callback

      process.nextTick ->
        config._update null,
          nil:
            nil: 'new'

        assert.calledTwice callback
        assert.calledWith callback, undefined, null
        assert.calledWith callback, null, 'new'
        assert.notCalled unexpected
        done()

    it "does not call watcher with null to null", (done) ->
      config.watch 'nil', callback

      process.nextTick ->
        config._update null,
          nil: null

        assert.calledOnce callback
        assert.calledWith callback, undefined, null
        assert.notCalled unexpected
        done()

    it "calls watcher of parent object of unhandled value", (done) ->
      config.watch 'bar', callback

      process.nextTick ->
        config._update null,
          bar:
            baz: 'other'

        assert.calledTwice callback
        assert.calledWith callback, undefined, baz: 'test'
        assert.calledWith callback, {baz: 'test'}, {baz: 'other'}
        assert.notCalled unexpected
        done()

    it "calls all watchers", (done) ->
      callback2 = sinon.stub()

      config.watch 'foo', callback
      config.watch 'foo', callback2

      process.nextTick ->
        config._update null,
          foo: 20

        assert.calledTwice callback
        assert.calledWith callback, 10, 20
        assert.calledTwice callback2
        assert.calledWith callback2, 10, 20
        assert.notCalled unexpected
        done()

  describe "unexpected", ->
    it "warns about changes to variable not watched", (done) ->
      config.watch 'bar', callback

      process.nextTick ->
        config._update null,
          foo: 20

        assert.calledOnce unexpected
        assert.calledWith unexpected, 'foo'
        done()

    it "warns about changes to deep variable not watched", (done) ->
      config.watch 'bar.baz', callback

      process.nextTick ->
        config._update null,
          bar:
            bob: 20

        assert.calledOnce unexpected
        assert.calledWith unexpected, 'bar.bob'
        done()
