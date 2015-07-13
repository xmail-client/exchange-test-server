EWSParser = require '../lib/ews-parser'
Builder = require 'libxmljs-builder'
NS = require '../lib/ews-ns'
should = require 'should'
Q = require 'q'
[NS_T, NS_M] = [NS.NS_TYPES, NS.NS_MESSAGES]
FolderChange = require '../lib/folder-change'
Folder = require '../lib/folder'

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
    builder.nodeNS NS_M, 'FolderIds', (builder) =>
      @buildDistinguishFolderId(builder, folderId) for folderId in folderIds

  buildDistinguishFolderId: (builder, folderId) ->
    builder.nodeNS NS_T, 'DistinguishedFolderId', Id: folderId

  buildParentFolderId: (builder, folderId) ->
    builder.nodeNS NS_M, 'ParentFolderId', (builder) =>
      @buildDistinguishFolderId(builder, folderId)

  buildToFolderId: (builder, folderId) ->
    builder.nodeNS NS_M, 'ToFolderId', (builder) =>
      @buildDistinguishFolderId(builder, folderId)

class GetFolderRequest extends RequestConstructor
  build: (folderIds) ->
    @_buildAction 'GetFolder', (builder) =>
      builder.nodeNS NS_M, 'FolderShape', (builder) ->
        builder.nodeNS NS_T, 'BaseShape', 'Default'
      @buildFolderIds(builder, folderIds)

class CreateFolderRequest extends RequestConstructor
  build: (displayName) ->
    @_buildAction 'CreateFolder', (builder) =>
      @buildParentFolderId(builder, displayName)
      builder.nodeNS NS_M, 'Folders', (builder) ->
        builder.nodeNS NS_T, 'Folder', (builder) ->
          builder.nodeNS NS_T, 'DisplayName', displayName

class DeleteFolderRequest extends RequestConstructor
  build: (displayName) ->
    @_buildAction 'DeleteFolder', (builder) =>
      @buildFolderIds builder, [displayName]

class CopyFolderRequest extends RequestConstructor
  build: (parentName, newName) ->
    @_buildAction 'CopyFolder', (builder) =>
      @buildToFolderId(builder, parentName)
      @buildFolderIds builder, [newName]

class MoveFolderRequest extends RequestConstructor
  build: (parentName, moveName) ->
    @_buildAction 'MoveFolder', (builder) =>
      @buildToFolderId(builder, parentName)
      @buildFolderIds builder, [moveName]

class FindFolderRequest extends RequestConstructor
  build: (parentName) ->
    @_buildAction 'FindFolder', (builder) =>
      builder.nodeNS NS_M, 'ParentFolderIds', (builder) =>
        @buildDistinguishFolderId(builder, parentName)

class UpdateFolderRequest extends RequestConstructor
  build: (folderId, newName) ->
    @_buildAction 'UpdateFolder', (builder) =>
      builder.nodeNS NS_M, 'FolderChanges', (builder) ->
        builder.nodeNS NS_T, 'FolderChange', (builder) ->
          builder.nodeNS NS_T, 'FolderId', 'Id': folderId
          builder.nodeNS NS_T, 'Updates', (builder) ->
            builder.nodeNS NS_T, 'SetFolderField', (builder) ->
              builder.nodeNS NS_T, 'FieldURI', FieldURI: 'folder:DisplayName'
              builder.nodeNS NS_T, 'Folder', (builder) ->
                builder.nodeNS NS_T, 'DisplayName', newName

class SyncFolderHierarchyRequest extends RequestConstructor
  build: (syncState) ->
    @_buildAction 'SyncFolderHierarchy', (builder) ->
      builder.nodeNS NS_M, 'SyncState', syncState.toString() if syncState

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
      FolderChange.fetchAll()
    .then (collection) ->
      collection.length.should.equal 1
      collection.at(0).getChanges().should.eql {"3": "create"}
      done()
    .catch done

  it 'DeleteFolderRequest test', (done) ->
    doc = new DeleteFolderRequest().build('inbox')
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      new Folder(displayName: 'inbox').fetch()
    .then (folder) ->
      should.equal(folder, null)
      FolderChange.fetchAll()
    .then (collection) ->
      collection.length.should.equal 1
      collection.at(0).getChanges().should.eql {"2": "delete"}
      done()
    .catch done

  it 'CopyFolderRequest test', (done) ->
    doc = new CopyFolderRequest().build('inbox', 'msgfolderroot')
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:Folders/*/t:FolderId'
      folderIdNode = resDoc.get(path, NS.NAMESPACES)
      folderIdNode.attr('Id').value().should.equal '3'
      new Folder(id: 3).fetch()
    .then (copyFolder) ->
      copyFolder.get('parentId').should.equal 2
      done()
    .catch done

  it 'MoveFolderRequest test', (done) ->
    doc = new MoveFolderRequest().build('msgfolderroot', 'inbox')
    new EWSParser().parse doc.toString()
    .then (resDoc) -> done()
    .catch done

  it 'FindFolderRequest test', (done) ->
    doc = new FindFolderRequest().build('msgfolderroot')
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:Folders/t:Folder'
      folderNodes = resDoc.find(path, NS.NAMESPACES)
      folderNodes.length.should.equal 1
      done()
    .catch done

  it 'UpdateFolderRequest test', (done) ->
    doc = new UpdateFolderRequest().build(2, 'new-inbox')
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      new Folder(id: 2).fetch()
    .then (folder) ->
      folder.get('displayName').should.equal 'new-inbox'
      done()
    .catch done

  createFolder = (name) ->
    new EWSParser().parse new CreateFolderRequest().build(name)

  it.only 'SyncFolderHierarchyRequest test', (done) ->
    Q.all([createFolder('folder1'), createFolder('folder2')]).then ->
      new EWSParser().parse new SyncFolderHierarchyRequest().build()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:Changes/t:Create'
      createNodes = resDoc.find(path, NS.NAMESPACES)
      createNodes.length.should.equal 2
      done()
    .catch done
