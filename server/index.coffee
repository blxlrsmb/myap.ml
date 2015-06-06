restify = require 'restify'
redis = require 'redis'
Q = require 'q'
utils = require './utils'
wechat = require './wechat'

logger = utils.logging.newConsoleLogger module.filename

redisConnection = redis.createClient
  parser: 'hiredis'

checkIdExistence = (id) ->
  Q.ninvoke redisConnection, 'get', "event:#{id}"
  .then (v) ->
    v?

getIdData = (id) ->
  Q.ninvoke redisConnection, 'get', "event:#{id}"
  .then JSON.parse

appendIdData = (id, entry) ->
  getIdData id
  .then (data) ->
    data ?= []
    data.push entry
    redisConnection.set "event:#{id}", JSON.stringify(data)

getIdLastTimestamp = (id) ->
  Q.ninvoke redisConnection, 'get', "event:#{id}"
  .then JSON.parse
  .then (res) ->
    res[res.length - 1].timestamp

respond = (req, res, next) ->
  id = req.params.id
  checkIdExistence id
  .then (r) ->
    if r
      getIdLastTimestamp id
      .then (timestamp) ->
        res.json
          lastTimestamp: timestamp
        next()
    else
      res.json
        lastTimestamp: 0
      next()
  .done()

recordLog = (req, res, next) ->
  id = req.params.id
  appendIdData id,
    timestamp: (new Date()).getTime() // 1000
  .then ->
    res.send 200
    next()
  .done()

server = restify.createServer()
server.use restify.acceptParser(server.acceptable)
server.use restify.bodyParser()
server.use restify.queryParser()
server.get '/wechat', wechat.authenticationHandler
server.post '/wechat', wechat.echoHandler
server.get '/client/:id', respond
server.post '/client/:id', recordLog

server.listen 8080, ->
  logger.debug 'server started'
