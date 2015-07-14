# exchange-test-server
[![NPM version][npm-image]][npm-url] [![Build Status][travis-image]][travis-url] [![Dependency Status][daviddm-image]][daviddm-url] [![Coverage Status][coveralls-image]][coveralls-url]

The test server that implement the EWS API


## Install

```bash
$ npm install --save exchange-test-server
```


## Usage

### start the test server

```coffee
server = new Server()
server.start {port: 3000}, ->
  console.log 'server listen on localhost:3000'
```

### start the test server and send the SOAP request
```coffee
Server = require 'exchange-test-server'
Builder = require 'libxmljs-builder'
http = require 'http'
NS =
  NS_SOAP: 'soap'
  NS_TYPES: 't'
  NS_MESSAGES: 'm'
  NAMESPACES:
    soap: 'http://schemas.xmlsoap.org/soap/envelope/'
    t: 'http://schemas.microsoft.com/exchange/services/2006/types'
    m: 'http://schemas.microsoft.com/exchange/services/2006/messages'

[NS_T, NS_M] = [NS.NS_TYPES, NS.NS_MESSAGES]

class RequestConstructor
  _build: (bodyCallback) ->
    @builder = new Builder
    @builder.defineNS NS.NAMESPACES
    @builder.rootNS NS.NS_SOAP, 'Envelope', (builder) ->
      builder.nodeNS NS.NS_SOAP, 'Body', bodyCallback

  _buildAction: (action, callback) ->
    @_build (builder) ->
      builder.nodeNS NS_M, action, callback

  buildFolderIds: (builder, folderIds) ->
    folderIds = [folderIds] unless Array.isArray(folderIds)
    builder.nodeNS NS_M, 'FolderIds', (builder) =>
      @buildDistinguishFolderId(builder, folderId) for folderId in folderIds

  buildDistinguishFolderId: (builder, folderId) ->
    builder.nodeNS NS_T, 'DistinguishedFolderId', Id: folderId

class GetFolderRequest extends RequestConstructor
  build: (folderIds) ->
    @_buildAction 'GetFolder', (builder) =>
      builder.nodeNS NS_M, 'FolderShape', (builder) ->
        builder.nodeNS NS_T, 'BaseShape', 'Default'
      @buildFolderIds(builder, folderIds)

dbPath = require('path').resolve(__dirname, 'data/db.sqlite')
server = new Server()
server.start dbPath: dbPath, ->
  console.log 'server start'

  config =
    port: 3000, method: 'POST', path: '/EWS/Exchange.asmx'
    headers: 'Content-Type': 'text/xml'

  req = http.request config, (res) ->
    console.log 'Done'
    server.close()
  req.end new GetFolderRequest().build('inbox').toString()

```

## API

_(Coming soon)_


## Contributing

In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [gulp](http://gulpjs.com/).


## License

Copyright (c) 2015 liuxiong. Licensed under the MIT license.



[npm-url]: https://npmjs.org/package/exchange-test-server
[npm-image]: https://badge.fury.io/js/exchange-test-server.svg
[travis-url]: https://travis-ci.org/liuxiong332/exchange-test-server
[travis-image]: https://travis-ci.org/liuxiong332/exchange-test-server.svg?branch=master
[daviddm-url]: https://david-dm.org/liuxiong332/exchange-test-server
[daviddm-image]: https://david-dm.org/liuxiong332/exchange-test-server.svg?theme=shields.io
[coveralls-url]: https://coveralls.io/r/liuxiong332/exchange-test-server
[coveralls-image]: https://coveralls.io/repos/liuxiong332/exchange-test-server/badge.png
