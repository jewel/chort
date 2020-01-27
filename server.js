var express = require('express');
var bus = require('statebus').serve({ port: 3000 });
bus.http.use('/', express.static('public'));
bus.http.use('/emoji', express.static('node_modules/asturur-noto-emoji/svg'))
bus.serve_clientjs();
