sinon = require 'sinon'

chain = (funs) ->
    ->
        funs.shift().apply null, arguments

describe "Config", ->
    Config = require '../../lib/runtime-config'

    base =
        foo: 10
        arr: [1..3]
        bar:
            baz: 'test'
    config = null

    beforeEach ->
        config = new Config path: 'test/data/runtime.json', base

    afterEach ->
        config.watcher.close()

    describe "watch", ->
        it "calls watcher with value from base", (done) ->
            config.watch 'foo', (old, value) ->
                assert.equal value, 10
                done()

        it "calls watcher with deep value from base", (done) ->
            config.watch 'bar.baz', (old, value) ->
                assert.equal value, 'test'
                done()

        # Document current behaivour not sure if this is how it should work
        it "calls watcher with undefined for missing value", (done) ->
            config.watch 'bar.bar', (old, value) ->
                assert.equal value, undefined
                done()

        it "calls watcher with undefined for missing parent value", (done) ->
            config.watch 'baz.baz', (old, value) ->
                assert.equal value, undefined
                done()

    describe "update", ->
        it "calls watcher with updated value", (done) ->
            config.watch 'foo', chain [
                (old, value) ->
                    assert.equal value, 10
                    assert.equal old, undefined
                (old, value) ->
                    assert.equal value, 20
                    assert.equal old, 10
                    done()
            ]

            process.nextTick ->
                config._update null,
                    foo: 20

        it "calls watcher with updated array", (done) ->
            config.watch 'arr', chain [
                (old, value) ->
                    assert.deepEqual value, [1..3]
                    assert.equal old, undefined
                (old, value) ->
                    assert.deepEqual value, [1..4]
                    assert.deepEqual old, [1..3]
                    done()
            ]

            process.nextTick ->
                config._update null,
                    arr: [1..4]

        it "calls watcher with new value", (done) ->
            config.watch 'baz', chain [
                (old, value) ->
                    assert.equal value, undefined
                    assert.equal old, undefined
                (old, value) ->
                    assert.equal value, 50
                    assert.equal old, undefined
                    done()
            ]

            process.nextTick ->
                config._update null,
                    baz: 50

        it "calls watcher with updated deep value", (done) ->
            config.watch 'bar.baz', chain [
                (old, value) ->
                    assert.equal value, 'test'
                    assert.equal old, undefined
                (old, value) ->
                    assert.equal value, 'other'
                    assert.equal old, 'test'
                    done()
            ]

            process.nextTick ->
                config._update null,
                    bar:
                        baz: 'other'

        it "calls all watchers", (done) ->
            firstCall = secondCall = false

            config.watch 'foo', (old, value) ->
                assert.equal value, 10
                firstCall = true
                done() if secondCall

            config.watch 'foo', (old, value) ->
                assert.equal value, 10
                secondCall = true
                done() if firstCall
