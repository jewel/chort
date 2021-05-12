var express = require('express');
var bus = require('statebus').serve({ port: 4111 });
bus.http.use('/', express.static('public'));
bus.http.use('/emoji', express.static('node_modules/asturur-noto-emoji/svg'))
bus.serve_clientjs();
