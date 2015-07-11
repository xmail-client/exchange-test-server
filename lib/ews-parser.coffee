{NAMESPACES} = require './ews-ns'
libxml = require 'libxmljs'
Folder = require './folder'
{GetFolderResponse} = require './response-generator'

class RequestDOMParser
  parse: (body) ->
    doc = libxml.parseXmlString body
    path = '/soap:Envelope/soap:Body/*'
    actionNode = doc.get(path, NAMESPACES)
    switch actionNode.name()
      when 'GetFolder':
        new GetFolderResponse().generate @parseGetFolder(actionNode)

  parseFolderId: (folderIdNode) ->
    folderIdNode.attr('Id')

  parseFolderIds: (folderIdsNode) ->
    for folderIdNode in folderIdsNode.childNodes()
      if folderIdNode.name() is 'DistinguishedFolderId'
        new Folder(id: @parseFolderId(folderIdNode)).fetch()
      else
        new Folder(displayName: @parseFolderId(folderIdNode)).fetch()

  parseGetFolder: (getFolderNode) ->
    folderIdsNode = getFolderNode.get('m:FolderIds', NAMESPACES)
    @parseFolderIds(folderIdsNode)
