util = require 'util'
restify = require 'restify'
Q = require 'q'
_ = require 'lodash'
utils = require './utils'
wechat = require './wechat'
database = require './database'

logger = utils.logging.newConsoleLogger module.filename

redisConnection = database.getConnection()

checkIdExistence = (id) ->
  Q.ninvoke redisConnection, 'llen', "event:#{id}"
  .then (v) ->
    v

getIdData = (id) ->
  Q.ninvoke redisConnection, 'lrange', "event:#{id}", 0, -1

appendIdData = (id, entry) ->
  Q.ninvoke redisConnection, 'lpush', "event:#{id}", JSON.stringify(entry)

getIdLastTimestamp = (id) ->
  Q.ninvoke redisConnection, 'lindex', "event:#{id}", 0
  .then JSON.parse
  .then (res) ->
    res.end

getLastTimestampHandler = (req, res, next) ->
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

recordHandler = (req, res, next) ->
  console.log 'params:'
  console.dir req.params
  console.log 'body:'
  console.log util.inspect(req.body,
    depth: null
  )
  id = req.params.id
  Q.all _.map(req.body.data, (i) ->
    appendIdData id, i
  )
  .then ->
    res.send 200
    next()
  .done()

summaryHandler = (req, res, next) ->
  globalStart = 1433590000
  globalEnd = 1433600000
  id = 233
  interval = 5
  consecutive = 3
  getIdData id
  .then (data) ->
    _.map data, (i) ->
      JSON.parse i
  .then (parsed) ->
    buckets = {}
    filtered = _.filter parsed, (i) ->
      globalStart <= i.start <= i.end < globalEnd
    _.map filtered, (i) ->
      # assume end - start is never greater than 10
      indexLeft = (i.start - globalStart) // interval
      indexRight = (i.end - globalStart) // interval
      if indexLeft == indexRight
        for app, count of i.key
          buckets[app] ?= []
          buckets[app][indexLeft] ?= 0
          buckets[app][indexLeft] += count
      else
        mid = indexRight * interval + globalStart
        coefficientLeft = (mid - i.start) / (i.end - i.start)
        coefficientRight = 1 - coefficientLeft
        for app, count of i.key
          leftCount = Math.floor coefficientLeft * count
          rightCount = count - leftCount
          buckets[app] ?= []
          buckets[app][indexLeft] ?= 0
          buckets[app][indexLeft] += leftCount
          buckets[app][indexLeft + 1] ?= 0
          buckets[app][indexLeft + 1] += rightCount
    ret = {}
    for app of buckets
      ret[app] = []
      startIndex = -1
      lastValidIndex = -1
      cnt = []
      for bucket, i in buckets[app]
        if bucket
          if startIndex == -1
            startIndex = i
            lastValidIndex = i
            cnt = [bucket]
          else
            if 1 < i - lastValidIndex
              _.map _.range(i - lastValidIndex - 1), ->
                cnt.push 0
            lastValidIndex = i
            cnt.push bucket
        else
          if lastValidIndex != -1 and consecutive < i - lastValidIndex
            ret[app].push
              start: startIndex * interval + globalStart
              end: (lastValidIndex + 1) * interval + globalStart
              count: cnt
            startIndex = -1
            lastValidIndex = -1
    res.json
      data: ret
  .done()

server = restify.createServer()
server.use restify.acceptParser(server.acceptable)
server.use restify.queryParser()
server.use restify.bodyParser
  mapParams: false
  # overrideParams: false
server.get '/wechat', wechat.authenticationHandler
server.post '/wechat', wechat.rpcHandler
server.get '/client/:id', getLastTimestampHandler
server.post '/client/:id', recordHandler
server.get '/summary', summaryHandler

server.listen 8080, ->
  logger.debug 'server started'
