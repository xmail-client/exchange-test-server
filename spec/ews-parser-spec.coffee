EWSParser = require '../lib/ews-parser'
Builder = require 'libxmljs-builder'
NS = require '../lib/ews-ns'
[NS_T, NS_M] = [NS.NS_TYPES, NS.NS_MESSAGES]

class RequestConstructor
  _build: (bodyCallback) ->
    @builder = new Builder
    @builder.defineNS NS.NAMESPACES
    @builder.rootNS NS.NS_SOAP, 'Envelope', (builder) ->
      builder.nodeNS NS.NS_SOAP, 'Body', bodyCallback

class GetFolderRequest extends RequestConstructor
  build: (folderIds) ->
    @_build (builder) ->
      builder.nodeNS NS_M, 'GetFolder', (builder) ->
        builder.nodeNS NS_M, 'FolderShape', (builder) ->
          builder.nodeNS NS_T, 'BaseShape', 'Default'
        builder.nodeNS NS_M, 'FolderIds', (builder) ->
          for folderId in folderIds
            builder.nodeNS NS_T, 'DistinguishedFolderId', Id: folderId

class CreateFolderRequest extends RequestConstructor
  build: (displayName) ->
    @_build (builder) ->
      builder.nodeNS NS_M, 'CreateFolder', (builder) ->
        builder.nodeNS NS_M, 'ParentFolderId', (builder) ->
          builder.nodeNS NS_T, 'DistinguishedFolderId', 'inbox'
        builder.nodeNS NS_M, 'Folders', (builder) ->
          builder.nodeNS NS_T, 'Folder', (builder) ->
            builder.nodeNS NS_T, 'DisplayName', displayName

describe 'EWSParser', ->
  it 'GetFolderRequest test', (done) ->
    doc = new GetFolderRequest().build(['inbox'])
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/m:ResponseMessages/*'
      msgNode = resDoc.get(path, NS.NAMESPACES)
      foldersNode = msgNode.get('m:Folders', NS.NAMESPACES)
      foldersNode.childNodes().length.should.equal 1
      folderNode = foldersNode.get('t:Folder', NS.NAMESPACES)
      nameNode = folderNode.get('t:DisplayName', NS.NAMESPACES)
      nameNode.text().should.equal 'inbox'
    .then -> done()
    .catch done

  it 'CreateFolderRequest test', (done) ->
    doc = new CreateFolderRequest().build('my-folder')
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/m:ResponseMessages/*'
      msgNode = resDoc.get(path, NS.NAMESPACES)
      folderIdNode = msgNode.get('m:Folders/t:Folder/t:FolderId', NS.NAMESPACES)
      folderIdNode.attr('Id').value().should.equal '3'
    .then ->
      FolderChange = require '../lib/folder-change'
      FolderChange.fetchAll()
    .then (collection) ->
      collection.length.should.equal 1
      done()
    .catch done