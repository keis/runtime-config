var fs = require('fs')
  , readJson = require('read-json-file')

module.exports = Config

// A super naive deep extend with a callback for each change
function update(dst, src, prefix, callback) {
  var key
    , sval
    , dval
    , clone

  for (key in src) {
    if (!src.hasOwnProperty(key)) {
      continue
    }

    sval = src[key]
    dval = dst[key]

    if (typeof sval !== 'object' || sval === null ||
      typeof dval !== 'object' || dval === null ||
      Array.isArray(sval) || Array.isArray(dval)
    ) {
      if (sval !== dval) {
        dst[key] = sval
        callback(prefix + key, dval, sval)
      }
    }

    if (typeof sval === 'object' && typeof dval === 'object' &&
        !Array.isArray(sval) && !Array.isArray(dval)
    ) {
      clone = JSON.parse(JSON.stringify(dval));
      update(dval, sval, prefix + key + '.', callback)
      callback(prefix + key, clone, dval)
    }
  }
}

function getValue(val, key) {
  var parts = key.split('.')
    , part

  while (val && (part = parts.shift())) {
    val = val[part]
  }

  return val;
}

function setValue(val, key, newv) {
  var parts = key.split('.')
    , last = parts.pop()
    , part

  while ((part = parts.shift())) {
    val = (val[part] || (val[part] = {}))
  }

  if (val) {
    val[last] = newv;
  }
}

function Config(options, base) {
  var reload
    , update
    , path

  path = options.path || 'config/runtime.json'

  this.base = base
  this.runtime = {}
  this.watching = {}

  update = this._update.bind(this)

  this.watcher = fs.watch(path, function (event, filename) {
    if (event === 'change') {
      readJson(path, update)
    }
  });
  readJson(path, update)
}

Config.prototype._update = function (err, data) {
  var self = this

  if (err) {
    return
  }

  // TODO: Does actually not need to update / merge the dictionary diffing
  // the structure to generate the update events and then swapping the
  // runtime hash would also work.
  // what about deletes? Especially when value is present in base
  update(this.runtime, data, '', function (key, oldv, newv) {
    if (watchers = self.watching[key]) {
      watchers.forEach(function (cb) {
        cb(oldv, newv)
      })
    } else {
      console.error("unexpected key in runtime configuration", key)
    }
  })
}

Config.prototype.watch = function watch(key, callback) {
  var self = this
    , watchers

  if (watchers = this.watching[key]) {
    watchers.push(callback)
  }else {
    watchers = this.watching[key] = [callback]
  }

  process.nextTick(function () {
    var value = getValue(self.runtime, key)
    if (value === void 0) {
        value = getValue(self.base, key)
        setValue(self.runtime, key, value)
    }
    callback(void 0, value)
  })
}
