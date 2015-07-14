Builder = require 'libxmljs-builder'
NS = require '../lib/ews-ns'
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

  buildParentFolderId: (builder, folderId) ->
    builder.nodeNS NS_M, 'ParentFolderId', (builder) =>
      @buildDistinguishFolderId(builder, folderId)

  buildToFolderId: (builder, folderId) ->
    builder.nodeNS NS_M, 'ToFolderId', (builder) =>
      @buildDistinguishFolderId(builder, folderId)

exports.GetFolderRequest =
class GetFolderRequest extends RequestConstructor
  build: (folderIds) ->
    @_buildAction 'GetFolder', (builder) =>
      builder.nodeNS NS_M, 'FolderShape', (builder) ->
        builder.nodeNS NS_T, 'BaseShape', 'Default'
      @buildFolderIds(builder, folderIds)

exports.CreateFolderRequest =
class CreateFolderRequest extends RequestConstructor
  build: (displayName) ->
    @_buildAction 'CreateFolder', (builder) =>
      @buildParentFolderId(builder, displayName)
      builder.nodeNS NS_M, 'Folders', (builder) ->
        builder.nodeNS NS_T, 'Folder', (builder) ->
          builder.nodeNS NS_T, 'DisplayName', displayName

exports.DeleteFolderRequest =
class DeleteFolderRequest extends RequestConstructor
  build: (displayName) ->
    @_buildAction 'DeleteFolder', (builder) =>
      @buildFolderIds builder, [displayName]

exports.CopyFolderRequest =
class CopyFolderRequest extends RequestConstructor
  build: (parentName, newName) ->
    @_buildAction 'CopyFolder', (builder) =>
      @buildToFolderId(builder, parentName)
      @buildFolderIds builder, [newName]

exports.MoveFolderRequest =
class MoveFolderRequest extends RequestConstructor
  build: (parentName, moveName) ->
    @_buildAction 'MoveFolder', (builder) =>
      @buildToFolderId(builder, parentName)
      @buildFolderIds builder, [moveName]

exports.FindFolderRequest =
class FindFolderRequest extends RequestConstructor
  build: (parentName) ->
    @_buildAction 'FindFolder', (builder) =>
      builder.nodeNS NS_M, 'ParentFolderIds', (builder) =>
        @buildDistinguishFolderId(builder, parentName)

exports.UpdateFolderRequest =
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

exports.SyncFolderHierarchyRequest =
class SyncFolderHierarchyRequest extends RequestConstructor
  build: (syncState) ->
    @_buildAction 'SyncFolderHierarchy', (builder) ->
      builder.nodeNS NS_M, 'SyncState', syncState.toString() if syncState
