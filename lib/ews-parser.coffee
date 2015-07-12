Q = require 'q'
{NAMESPACES} = require './ews-ns'
libxml = require 'libxmljs'
Folder = require './folder'
{GetFolderResponse} = require './response-generator'

module.exports =
class RequestDOMParser
  parse: (body) ->
    doc = libxml.parseXmlString body
    path = '/soap:Envelope/soap:Body/*'
    actionNode = doc.get(path, NAMESPACES)
    switch actionNode.name()
      when 'GetFolder'
        @parseGetFolder(actionNode).then (folders) ->
          new GetFolderResponse().generate folders

  parseFolderId: (folderIdNode) ->
    folderIdNode.attr('Id').value()

  parseFolderIds: (folderIdsNode) ->
    promises = []
    for folderIdNode in folderIdsNode.childNodes()
      if folderIdNode.name() is 'DistinguishedFolderId'
        folderId = @parseFolderId(folderIdNode)
        promises.push new Folder(displayName: folderId).fetch()
      else if folderIdNode.name() is 'FolderId'
        promises.push new Folder(id: @parseFolderId(folderIdNode)).fetch()
    Q.all promises

  parseGetFolder: (getFolderNode) ->
    folderIdsNode = getFolderNode.get('m:FolderIds', NAMESPACES)
    @parseFolderIds(folderIdsNode)
