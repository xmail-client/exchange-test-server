Builder = require 'libxmljs-builder'
NS = require './ews-ns'

NS_T = NS.NS_TYPES
NS_M = NS.NS_MESSAGES

class ResponseGenerator
  build: (bodyCallback) ->
    @builder = new Builder
    @builder.defineNS NS.NAMESPACES
    @builder.rootNS NS.NS_SOAP, 'Envelope', (builder) ->
      builder.nodeNS NS.NS_SOAP, 'Body', bodyCallback

  buildAction: (action, resMsgCallback) ->
    @build (builder) => @buildResponse(builder, action, resMsgCallback)

  buildActions: (action, resMsgCallbacks) ->
    @build (builder) =>
      @buildResponse(builder, action, callback) for callback in resMsgCallbacks

  buildResponse: (builder, action, resMsgCallback) ->
    builder.nodeNS NS_M, "#{action}Response", (builder) ->
      builder.nodeNS NS_M, 'ResponseMessages', (builder) ->
        builder.nodeNS NS_M, "#{action}ResponseMessage",
          {ResponseClass: 'Success'}, (builder) ->
            builder.nodeNS NS_M, 'ResponseCode', 'NoError'
            resMsgCallback(builder)

  buildFolder: (builder, folder) ->
    builder.nodeNS NS_T, 'Folder', (builder) ->
      builder.nodeNS NS_T, 'FolderId', {Id: folder.id}
      builder.nodeNS NS_T, 'DisplayName', folder.get('displayName')

  buildFolders: (builder, folders) ->
    builder.nodeNS NS_M, 'Folders', (builder) =>
      for folder in folders
        @buildFolder(builder, folder)

class GetFolderResponse extends ResponseGenerator
  generate: (folders) ->
    @buildAction 'GetFolder', (builder) =>
      @buildFolders(builder, folders)

class CreateFolderResponse extends ResponseGenerator
  generate: (folders) ->
    @build (builder) =>
      folders.forEach (folder) =>
        @buildResponse builder, 'CreateFolder', (builder) =>
          @buildFolders(builder, [folder])

class DeleteFolderResponse extends ResponseGenerator
  generate: ->
    @buildAction 'DeleteFolder', ->

class CopyFolderResponse extends ResponseGenerator
  generate: (folders) ->
    @buildAction 'CopyFolder', (builder) =>
      @buildFolders builder, folders

module.exports = {GetFolderResponse, CreateFolderResponse,
  DeleteFolderResponse, CopyFolderResponse}
