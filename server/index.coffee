restify = require 'restify'
redis = require 'redis'
Q = require 'q'
utils = require './utils'
xml2js = require 'xml2js'

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

crypto = require 'crypto'

func2 = (req, res, next) ->
  xml2js.parseString req.body, (err, parsed) ->
    console.log req.body
    toUser = parsed.xml['FromUserName'][0]
    fromUser = parsed.xml['ToUserName'][0]
    createTime = (new Date()).getTime() // 1000
    content = "echo #{parsed.xml['Content'][0]}"
    ret = "
      <xml>
        <ToUserName><![CDATA[#{toUser}]]></ToUserName>
        <FromUserName><![CDATA[#{fromUser}]]></FromUserName>
        <CreateTime>#{createTime}</CreateTime>
        <MsgType><![CDATA[text]]></MsgType>
        <Content><![CDATA[#{content}]]></Content>
      </xml>"
    res.contentType='text'
    console.log ret
    res.send 200, ret
    next()
  console.log req.body

func = (req, res, next) ->
  console.log req.query
  token = 'EastIndiaCompany'
  timestamp = req.query['timestamp']
  nonce = req.query['nonce']
  signature = req.query['signature']
  echostr = req.query['echostr']
  l = [token, timestamp, nonce].sort()
  l = l.join ''
  shasum = crypto.createHash 'sha1'
  shasum.update l
  console.log l
  res.contentType='text'
  if shasum.digest('hex') == signature
    console.log 'ok'
    res.send 200, echostr
  else
    console.log 'no'
    res.send 200

server = restify.createServer()
server.use restify.acceptParser(server.acceptable)
server.use restify.bodyParser()
server.use restify.queryParser()
server.get '/', func
server.post '/', func2
server.get '/client/:id', respond
server.post '/client/:id', recordLog

server.listen 8080, ->
  logger.debug 'server started'
