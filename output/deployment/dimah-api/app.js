'use strict';

const { createApi } = require('./server');
const server = createApi();
server.requestTimeout = 15000;
server.headersTimeout = 10000;
server.listen(process.env.PORT || 3000);
