EWSParser = require '../lib/ews-parser'
NS = require '../lib/ews-ns'
should = require 'should'
Q = require 'q'
FolderChange = require '../lib/folder-change'
Folder = require '../lib/folder'
Request = require './request-helper'

describe 'EWSParser', ->
  it 'GetFolderRequest test', (done) ->
    doc = new Request.GetFolderRequest().build(['inbox'])
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
    doc = new Request.CreateFolderRequest().build('my-folder')
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
    doc = new Request.DeleteFolderRequest().build('inbox')
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
    doc = new Request.CopyFolderRequest().build('inbox', 'msgfolderroot')
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
    doc = new Request.MoveFolderRequest().build('msgfolderroot', 'inbox')
    new EWSParser().parse doc.toString()
    .then (resDoc) -> done()
    .catch done

  it 'FindFolderRequest test', (done) ->
    doc = new Request.FindFolderRequest().build('msgfolderroot')
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:Folders/t:Folder'
      folderNodes = resDoc.find(path, NS.NAMESPACES)
      folderNodes.length.should.equal 1
      done()
    .catch done

  it 'UpdateFolderRequest test', (done) ->
    doc = new Request.UpdateFolderRequest().build(2, 'new-inbox')
    new EWSParser().parse doc.toString()
    .then (resDoc) ->
      new Folder(id: 2).fetch()
    .then (folder) ->
      folder.get('displayName').should.equal 'new-inbox'
      done()
    .catch done

  createFolder = (name) ->
    new EWSParser().parse new Request.CreateFolderRequest().build(name)

  it 'SyncFolderHierarchyRequest test', (done) ->
    Q.all([createFolder('folder1'), createFolder('folder2')]).then ->
      new EWSParser().parse new Request.SyncFolderHierarchyRequest().build()
    .then (resDoc) ->
      path = '/soap:Envelope/soap:Body/*/*/*/m:Changes/t:Create'
      createNodes = resDoc.find(path, NS.NAMESPACES)
      createNodes.length.should.equal 2
      done()
    .catch done
