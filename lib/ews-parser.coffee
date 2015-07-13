Q = require 'q'
{NAMESPACES} = require './ews-ns'
libxml = require 'libxmljs'
Folder = require './folder'
FolderChange = require './folder-change'
Response = require './response-generator'

module.exports =
class RequestDOMParser
  parse: (body) ->
    doc = if typeof body is 'string' then libxml.parseXmlString(body) else body
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
      when 'MoveFolder'
        @parseMoveFolder(actionNode).then (folders) ->
          new Response.MoveFolderResponse().generate(folders)
      when 'FindFolder'
        @parseFindFolder(actionNode).then (folders) ->
          new Response.FindFolderResponse().generate(folders)
      when 'UpdateFolder'
        @parseUpdateFolder(actionNode).then (folders) ->
          new Response.UpdateFolderResponse().generate(folders)
      when 'SyncFolderHierarchy'
        @parseSyncFolderHierarchy(actionNode).then (res) ->
          new Response.SyncFolderHierarchyResponse().generate(res)

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

  addChanges = (action, folders) ->
    changes = {}
    changes[folder.id] = action for folder in folders
    new FolderChange(changes: JSON.stringify(changes)).save()

  addCreateChanges = (folders) -> addChanges('create', folders)

  addDeleteChanges = (folders) -> addChanges('delete', folders)

  addUpdateChanges = (folders) -> addChanges('update', folders)

  parseCreateFolder: (createFolderNode) ->
    parentNode = createFolderNode.get('m:ParentFolderId', NAMESPACES)
    foldersNode = createFolderNode.get('m:Folders', NAMESPACES)
    newFolders = null
    @parseFolders(foldersNode).then (folders) =>
      newFolders = folders
      @parseParentFolderId(parentNode)
    .then (parentFolder) ->
      promises = for folder in newFolders
        folder.set('parentId', parentFolder.id)
        folder.save()
      Q.all(promises).tap -> addCreateChanges(newFolders)

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
      Q.all(promises).tap -> addCreateChanges(newFolders)

  parseMoveFolder: (moveFolderNode) ->
    folderIdsNode = moveFolderNode.get('m:FolderIds', NAMESPACES)
    moveFolders = null
    @parseFolderIds(folderIdsNode).then (folders) ->
      moveFolders = folders
      addDeleteChanges(folders)
    .then =>
      toFolderIdNode = moveFolderNode.get('m:ToFolderId', NAMESPACES)
      @parseToFolderId(toFolderIdNode)
    .then (toFolder) ->
      promises = for folder in moveFolders
        folder.set('parentId', toFolder.id).save()
      Q.all(promises).tap -> addCreateChanges(moveFolders)

  parseFindFolder: (findFolderNode) ->
    parentFolderIdsNode = findFolderNode.get('m:ParentFolderIds', NAMESPACES)
    @parseParentFolderId(parentFolderIdsNode)
    .then (parentFolder) ->
      if parentFolder then parentFolder else new Folder(id: 1).fetch()
    .then (parentFolder) ->
      Folder.where(parentId: parentFolder.id).fetchAll()
    .then (collection) ->
      collection.at(i) for i in [0...collection.length]

  getChanges = (changeNode) ->
    fieldNodes = changeNode.find('t:Updates/t:SetFolderField', NAMESPACES)
    for fieldNode in fieldNodes
      fieldUriNode = fieldNode.get('t:FieldURI', NAMESPACES)
      if fieldUriNode.attr('FieldURI').value() is 'folder:DisplayName'
        text = fieldNode.get('t:Folder/t:DisplayName', NAMESPACES).text()
        return {displayName: text}

  parseUpdateFolder: (updateFolderNode) ->
    changePath = 'm:FolderChanges/t:FolderChange'
    changeNodes = updateFolderNode.find(changePath, NAMESPACES)
    updateFolders = []
    promises = for changeNode in changeNodes
      folderIdNode = changeNode.get('t:FolderId', NAMESPACES)
      new Folder(id: @_getIdFromNode(folderIdNode)).fetch().then (folder) ->
        changes = getChanges(changeNode)
        updateFolders.push folder
        if changes and changes.displayName
          folder.set('displayName', changes.displayName).save()
    Q.all(promises).tap -> addUpdateChanges(updateFolders)

  mergeChanges: (changeList) ->
    changes = {}
    for i in [0...changeList.length]
      changeRow = changeList.at(i)
      changeInfo = JSON.parse(changeRow.get('changes'))
      for id, status of changeInfo
        unless changes[id]
          changes[id] = status
        else
          switch changes[id]
            when 'create' then delete changes[id] if status is 'delete'
            when 'update' then changes[id] = 'delete' if status is 'delete'
    changes

  transformChanges: (changes) ->
    resChanges = {creates: [], updates: [], deletes: []}
    promises = for id, status of changes
      new Folder(id: parseInt(id)).fetch().then (folder) ->
        resChanges["#{status}s"].push folder
    Q.all(promises).then -> resChanges

  parseSyncFolderHierarchy: (syncFolderNode) ->
    syncStateNode = syncFolderNode.get('m:SyncState', NAMESPACES)
    initId = if syncStateNode then parseInt(syncStateNode.text()) else 0
    changeRows = null
    FolderChange.where('id', '>', initId).fetchAll().then (changes) =>
      changeRows = changes
      @transformChanges @mergeChanges(changes)
    .then (resChanges) ->
      if changeRows.length <= 0
        resChanges.syncState = initId
      else
        resChanges.syncState = changeRows.at(changeRows.length - 1).id
      resChanges
