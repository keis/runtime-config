var Runtime = require('./lib/runtime-config'),
    config = require('config'),
    runtime = new Runtime({}, config);

runtime.watch('foo.baz', function (oldv, newv) {
    console.log('it changed', oldv, newv);
});

setInterval(function () {
    console.log('tick');
}, 10000);
