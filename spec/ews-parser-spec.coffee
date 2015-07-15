EWSParser = require '../lib/ews-parser'
NS = require '../lib/ews-ns'
should = require 'should'
Q = require 'q'
DBInfo = require '../lib/db-info'
Models = require '../lib/models'
Request = require './request-helper'

describe 'EWSParser', ->
  [dbInfo, models] = []
  beforeEach (done) ->
    dbInfo = new DBInfo()
    dbInfo.createTables().then ->
      models = new Models(dbInfo.bookshelf)
      models.init()
    .then -> done()
    .catch done

  afterEach (done) ->
    dbInfo.destroyTables().then ->  dbInfo.close done

  it 'GetFolderRequest test', (done) ->
    doc = new Request.GetFolderRequest().build(['inbox'])
    new EWSParser(models).parse doc.toString()
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
    doc = new Request.CreateFolderRequest().build('my-folder')
    new EWSParser(models).parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/m:ResponseMessages/*'
      msgNode = resDoc.get(path, NS.NAMESPACES)
      folderIdNode = msgNode.get('m:Folders/t:Folder/t:FolderId', NS.NAMESPACES)
      folderIdNode.attr('Id').value().should.equal '3'
    .then ->
      models.FolderChange.fetchAll()
    .then (collection) ->
      collection.length.should.equal 1
      collection.at(0).getChanges().should.eql {"3": "create"}
      done()
    .catch done

  it 'DeleteFolderRequest test', (done) ->
    doc = new Request.DeleteFolderRequest().build('inbox')
    new EWSParser(models).parse doc.toString()
    .then (resDoc) ->
      new models.Folder(displayName: 'inbox').fetch()
    .then (folder) ->
      should.equal(folder, null)
      models.FolderChange.fetchAll()
    .then (collection) ->
      collection.length.should.equal 1
      collection.at(0).getChanges().should.eql {"2": "delete"}
      done()
    .catch done

  it 'CopyFolderRequest test', (done) ->
    doc = new Request.CopyFolderRequest().build('inbox', 'msgfolderroot')
    new EWSParser(models).parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:Folders/*/t:FolderId'
      folderIdNode = resDoc.get(path, NS.NAMESPACES)
      folderIdNode.attr('Id').value().should.equal '3'
      new models.Folder(id: 3).fetch()
    .then (copyFolder) ->
      copyFolder.get('parentId').should.equal 2
      done()
    .catch done

  it 'MoveFolderRequest test', (done) ->
    doc = new Request.MoveFolderRequest().build('msgfolderroot', 'inbox')
    new EWSParser(models).parse doc.toString()
    .then (resDoc) -> done()
    .catch done

  it 'FindFolderRequest test', (done) ->
    doc = new Request.FindFolderRequest().build('msgfolderroot')
    new EWSParser(models).parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:RootFolder/t:Folders/t:Folder'
      folderNodes = resDoc.find(path, NS.NAMESPACES)
      folderNodes.length.should.equal 1
      done()
    .catch done

  it 'UpdateFolderRequest test', (done) ->
    doc = new Request.UpdateFolderRequest().build(2, 'new-inbox')
    new EWSParser(models).parse doc.toString()
    .then (resDoc) ->
      new models.Folder(id: 2).fetch()
    .then (folder) ->
      folder.get('displayName').should.equal 'new-inbox'
      done()
    .catch done

  createFolder = (name) ->
    new EWSParser(models).parse new Request.CreateFolderRequest().build(name)

  it 'SyncFolderHierarchyRequest test', (done) ->
    Q.all([createFolder('folder1'), createFolder('folder2')]).then ->
      new EWSParser(models).parse new Request.SyncFolderHierarchyRequest().build()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:Changes/t:Create'
      createNodes = resDoc.find(path, NS.NAMESPACES)
      createNodes.length.should.equal 2
      done()
    .catch done
