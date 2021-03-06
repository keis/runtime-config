var fs = require('fs')
  , readJson = require('read-json-file')
  , union = require('array-union')
  , isObject = require('isobject')
  , getValue = require('get-value')
  , setValue = require('set-value')

module.exports = Config

// A super naive deep diff with a callback for each differing element if used
// with a nested structure the callback will be called once for the parent
// object and then once for each child that is different
function diff(dst, src, prefix, callback) {
  var keys = union(Object.keys(dst), Object.keys(src))
    , changes = 0
    , i = 0
    , key
    , sval
    , dval

  while ((key = keys[i++])) {
    sval = src[key]
    dval = dst[key]

    if (!isObject(sval) || !isObject(dval)) {
      if (sval !== dval) {
        callback(prefix + key, dval, sval)
        changes++
      }
    } else {
      if (diff(dval, sval, prefix + key + '.', callback)) {
        callback(prefix + key, dval, sval)
        changes++
      }
    }
  }
  return changes
}

function Config(options, base) {
  var update
    , path

  path = options.path || 'config/runtime.json'

  this.base = base
  this.runtime = {}
  this.watching = {}

  update = this._update.bind(this)

  this.watcher = fs.watch(path, function (event) {
    if (event === 'change') {
      readJson(path, update)
    }
  })
  readJson(path, update)
}

Config.prototype._unexpected = function (key) {
  console.error('unexpected key in runtime configuration', key)
}

Config.prototype._update = function (err, data) {
  var self = this
    , unexpected = []

  if (err) {
    return
  }

  // diff the current runtime with the new data and notify the watchers of any
  // changes and then replace the runtime hash with the new data to complete
  // the update.
  diff(this.runtime, data, '', function (key, oldv, newv) {
    var watchers

    if (newv === void 0) {
      newv = getValue(self.base, key)
      setValue(self.runtime, key, newv)
    }

    if ((watchers = self.watching[key])) {
      watchers.forEach(function (cb) {
        cb(oldv, newv)
      })
      unexpected = unexpected.filter(function (el) {
        return el.indexOf(key + '.') !== 0
      })
    } else if (!isObject(oldv) || !isObject(newv)) {
      unexpected.push(key)
    }
  })
  unexpected.forEach(this._unexpected)
  this.runtime = data
}

Config.prototype.watch = function watch(key, callback) {
  var self = this
    , watchers

  if ((watchers = this.watching[key])) {
    watchers.push(callback)
  }else {
    watchers = this.watching[key] = [callback]
  }

  // Call the watcher immediately in the next tick
  process.nextTick(function () {
    var value = getValue(self.runtime, key)
    if (value === void 0) {
      value = getValue(self.base, key)
      setValue(self.runtime, key, value)
    }
    callback(void 0, value)
  })
}
