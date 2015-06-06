restify = require 'restify'

respond = (req, res, next) ->
  console.dir req
  res.send 'hello ' + req.params.name
  next()

server = restify.createServer()
server.use restify.acceptParser(server.acceptable)
server.use restify.bodyParser()
server.get '/hello/:name', respond
server.post '/hello/:name', respond

server.listen 8080, ->
  console.log 'listening'