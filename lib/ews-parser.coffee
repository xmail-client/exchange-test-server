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

  parseParentFolderId: (parentFolderIdNode) ->
    @getFolderByFolderId parentFolderIdNode

  parseFolderId: (folderIdNode) ->
    folderIdNode.attr('Id').value()

  getFolderByFolderId: (folderIdNode) ->
    if folderIdNode.name() is 'DistinguishedFolderId'
      folderId = @parseFolderId(folderIdNode)
      new Folder(displayName: folderId).fetch()
    else if folderIdNode.name() is 'FolderId'
      new Folder(id: @parseFolderId(folderIdNode)).fetch()

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
      new FolderChange(changes: changes).save()
    .then =>
      @parseParentFolderId(parentNode)
    .then (parentFolder) ->
      folder.set('parent', parentFolder) for folder in newFolders