Q = require 'q'
{NAMESPACES} = require './ews-ns'
libxml = require 'libxmljs'
Folder = require './folder'
FolderChange = require './folder-change'
Response = require './response-generator'

module.exports =
class RequestDOMParser
  parse: (body) ->
    doc = libxml.parseXmlString body
    path = '/soap:Envelope/soap:Body/*'
    actionNode = doc.get(path, NAMESPACES)
    switch actionNode.name()
      when 'GetFolder'
        @parseGetFolder(actionNode).then (folders) ->
          new Response.GetFolderResponse().generate folders
      when 'CreateFolder'
        @parseCreateFolder(actionNode).then (folders) ->
          new Response.CreateFolderResponse().generate folders
      when 'DeleteFolder'
        @parseDeleteFolder(actionNode).then ->
          new Response.DeleteFolderResponse().generate()
      when 'CopyFolder'
        @parseCopyFolder(actionNode).then (folders) ->
          new Response.CopyFolderResponse().generate(folders)
      when 'FindFolder'
        @parseFindFolder(actionNode).then (folders) ->
          new Response.FindFolderResponse().generate(folders)

  _parseFolderId: (parentNode) ->
    for folderIdNode in parentNode.childNodes()
      promise = @getFolderByFolderId(folderIdNode)
      return promise if promise

  parseParentFolderId: (parentFolderIdNode) ->
    @_parseFolderId parentFolderIdNode

  parseToFolderId: (toFolderIdNode) ->
    @_parseFolderId toFolderIdNode

  _getIdFromNode: (folderIdNode) ->
    folderIdNode.attr('Id').value()

  getFolderByFolderId: (folderIdNode) ->
    if folderIdNode.name() is 'DistinguishedFolderId'
      folderId = @_getIdFromNode(folderIdNode)
      new Folder(displayName: folderId).fetch()
    else if folderIdNode.name() is 'FolderId'
      new Folder(id: @_getIdFromNode(folderIdNode)).fetch()

  parseFolderIds: (folderIdsNode) ->
    promises = []
    for folderIdNode in folderIdsNode.childNodes()
      promise = @getFolderByFolderId(folderIdNode)
      promises.push promise if promise
    Q.all promises

  parseFolder: (folderNode) ->
    displayName = folderNode.get('t:DisplayName', NAMESPACES).text()
    new Folder(displayName: displayName).save()

  parseFolders: (foldersNode) ->
    folderNodes = foldersNode.find('t:Folder', NAMESPACES)
    promises = for folderNode in folderNodes
      @parseFolder(folderNode)
    Q.all promises

  parseGetFolder: (getFolderNode) ->
    folderIdsNode = getFolderNode.get('m:FolderIds', NAMESPACES)
    @parseFolderIds(folderIdsNode)

  parseCreateFolder: (createFolderNode) ->
    parentNode = createFolderNode.get('m:ParentFolderId', NAMESPACES)
    foldersNode = createFolderNode.get('m:Folders', NAMESPACES)
    newFolders = null
    @parseFolders(foldersNode).then (folders) ->
      newFolders = folders
      changes = {}
      changes[folder.id] = 'create' for folder in folders
      new FolderChange(changes: JSON.stringify(changes)).save()
    .then =>
      @parseParentFolderId(parentNode)
    .then (parentFolder) ->
      promises = for folder in newFolders
        folder.set('parentId', parentFolder.id)
        folder.save()
      Q.all promises

  parseDeleteFolder: (deleteFolderNode) ->
    folderIdsNode = deleteFolderNode.get('m:FolderIds', NAMESPACES)
    @parseFolderIds(folderIdsNode).then (folders) ->
      changes = {}
      promises = for folder in folders when folder?
        changes[folder.id] = 'delete'
        folder.destroy()
      promises.push new FolderChange(changes: JSON.stringify(changes)).save()
      Q.all promises

  parseCopyFolder: (copyFolderNode) ->
    folderIdsNode = copyFolderNode.get('m:FolderIds', NAMESPACES)
    newFolders = null
    @parseFolderIds(folderIdsNode).then (folders) ->
      promises = for folder in folders
        new Folder(displayName: folder.get('displayName')).save()
      Q.all promises
    .then (folders) =>
      newFolders = folders
      toFolderIdNode = copyFolderNode.get('m:ToFolderId', NAMESPACES)
      @parseToFolderId(toFolderIdNode)
    .then (toFolder) ->
      promises = for folder in newFolders
        folder.set('parentId', toFolder.id)
        folder.save()
      Q.all promises

  parseFindFolder: (findFolderNode) ->
    parentFolderIdsNode = findFolderNode.get('m:ParentFolderIds', NAMESPACES)
    @parseParentFolderId(parentFolderIdsNode)
    .then (parentFolder) ->
      if parentFolder then parentFolder else new Folder(id: 1).fetch()
    .then (parentFolder) ->
      Folder.where(parentId: parentFolder.id).fetchAll()
    .then (collection) ->
      collection.at(i) for i in [0...collection.length]
