fetch = require 'node-fetch'
querystring = require 'querystring'

module.exports = {

  create: (graph,opts) ->
    @.opts = opts
    @.opts.verbose = @.opts.verbose || 0
    @.opts.requestfunc = ( if typeof fetch is 'function' then fetch else window.fetch )
    omg = @

    @.onError = () ->
      console.error "ohmygraph exception: "
      console.log JSON.stringify arguments,null,2
    
    @.onWarning = (err) ->
      console.error "ohmygraph warning: "
      console.log JSON.stringify err,null,2 if err?

    @.clone = (obj) -> 
      return obj if obj == null or typeof obj != 'object' or typeof obj == 'function'
      temp = obj.constructor()
      temp[key] = @.clone(obj[key]) for key of obj
      temp

    @.jref = require 'json-ref-lite'
    @.graph = @.jref.resolve graph
    @.get  = (node) -> 
      return @.onError {err:"node "+node+" does not exist"} if not @.graph[node] or not @.graph[node].properties? 
      @.graph[node].properties
   
    @.init_events = (node) ->
      node.listeners = {}
      node.on        = (event,cb) -> 
        node.listeners[event] = [] if not node.listeners[event]?
        node.listeners[event].push cb

      node.trigger = (event,data) -> 
        console.log node.name+".on "+event+" ("+node.listeners[event].length+" listeners)" if omg.opts.verbose > 0
        ( handler data for handler in node.listeners[event] ) if node.listeners[event]?
 
    @.init_node = (nodename,node) ->
      node.name = nodename
      # quick data utils
      node.clone     = () -> omg.clone node
      node.set       = (key,value) -> node.data[key] = value
      node.populate = (properties) ->
        ( node.set x,y,node for x,y of properties ) if properties?
      node.on = (event,cb) -> omg.graph[node.name].on event,cb
      node.trigger = (event,data) -> omg.graph[node.name].trigger event,data
      
      # bind client requests
      node.bindrequests = (node) ->
        if node.request?
          node.requestor = {}
          for methodtype,request of node.request
            node.requestor[methodtype] = ( (graph,node,request,nodename) ->
              (properties) ->
                node.data = properties if properties? and typeof properties is 'object'
                tmpgraph = omg.clone graph                         # lets create a temporary graph
                tmpgraph[node.name] = node                         # and replace the schemanode with this node
                req = omg.jref.evaluate request.config, tmpgraph   # so we can evaluate nodespecific values
                req.url = req.url+"?"+querystring.stringify req.payload if req.method is 'get' and req.payload? and Object.keys(req.payload).length
                req.url = ( if omg.opts.baseurl then omg.opts.baseurl else '' ) + req.url
                console.log req.method+" "+req.url if omg.opts.verbose > 0
                console.dir req if omg.opts.verbose > 1
                omg.opts.requestfunc req.url,
                  method: req.method
                  body: ( if req.method is 'get' then '' else JSON.stringify req.payload )
                .then( (res) -> res.json() ).then (json) ->
                  request.response = json
                  if request.data?
                    result = ( omg.jref.evaluate( {'_':request.data}, {response:request.response} ) )['_']
                    throw {err:"could not parse '"+request.data+"' from "+nodename+"'s response",response:json} if not result?
                    if node.type is "array"
                      node.data = []
                      schemanode = node.items[0]
                      throw {err:"node '"+nodename+"' has invalid 'items' reference",node:node} if not schemanode?
                      for item in result
                        o = omg.clone schemanode                      # clone jsonschema node
                        omg.init_node o.name,o
                        o.data = item 
                        node.data.push o
                      node.trigger 'data', node.data
                    else 
                      node.data = result
                      node.trigger 'data', node
                .catch omg.onError
            )(graph,node,request,nodename)
            node[methodtype] = node.requestor[methodtype] # shortcut functions

      node.bindrequests(node)

    @.init = {}
    @.init.client = () ->
      graph = omg.graph
      for nodename,node of graph
        ( (nodename,node) ->
          omg.init_node nodename,node
          omg.init_events node        
        )(nodename,node)

    @
}
