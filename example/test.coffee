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
    headers:
      'Content-Type': 'text/xml'

  req = http.request config, (res) ->
    console.log 'Done'
    server.close()
  req.end new GetFolderRequest().build('inbox').toString()
