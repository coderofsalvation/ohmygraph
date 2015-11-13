fetch = require 'node-fetch'
querystring = require 'querystring'
jref = require 'json-ref-lite'

module.exports = {
    
  jref: jref

  # create graph
  create: (graph = {},opts = {}) ->
    @.jref = jref

    @.opts = opts
    @.opts.verbose = @.opts.verbose || 0
    @.opts.requestfunc = ( if typeof fetch is 'function' then fetch else () -> window.fetch.apply(window,arguments) )
    omg = @

    
    # customizable error/catch function
    @.onError = () => 
      console.error "ohmygraph exception: "
      console.dir arguments
      #debugger if window? and @.opts.verbose > 1
    
    # customizable warning function
    @.onWarning = (err) -> 
      console.error "ohmygraph warning: "
      console.log JSON.stringify err,null,2 if err?

    # deep clone object utility function
    @.clone = (obj) -> 
      return obj if obj == null or typeof obj != 'object' or typeof obj == 'function'
      temp = obj.constructor()
      temp[key] = @.clone(obj[key]) for key of obj
      temp

    # access your resolved graph here
    @.graph = graph

    # get node with name x
    @.get  = (node) -> 
      return @.onError {err:"node "+node+" does not exist"} if not @.graph[node] or not @.graph[node].properties? 
      @.graph[node].properties
   
    @.init_events = (node) ->
      node.listeners = {}
      node.on        = (event,cb) -> 
        node.listeners[event] = [] if not node.listeners[event]?
        node.listeners[event].push cb

      node.trigger = (event,data) -> 
        return if not node.listeners[event]?
        console.log node.name+".on "+event+" ("+node.listeners[event].length+" listeners)" if omg.opts.verbose > 0
        ( handler data for handler in node.listeners[event] ) if node.listeners[event]?
 
    @.init_node = (nodename,node) ->
      node.name = nodename
      # call clone() on a node to keep the original intact 
      node.clone     = () -> omg.clone node
      node.set       = (key,value) -> node.data[key] = value
      node.populate = (properties) ->
        ( node.set x,y,node for x,y of properties ) if properties?
      # register an event on your node: node.on( 'foo', function(){} )
      node.on = (event,cb) -> omg.graph[node.name].on event,cb
      # trigger an event on your node: node.trigger('foo',{data:'bar'})
      node.trigger = (event,data) -> omg.graph[node.name].trigger event,data
      
      # autobind client requesthandlers on node
      node.bindrequests = (node) ->
        if node.request?
          node.requestor = {}
          for methodtype,request of node.request
            node.requestor[methodtype] = ( (graph,node,request,nodename) ->
              (properties) ->
                alert("todo") if properties?
                #graph[node.name].data = properties if properties? and typeof properties is 'object'
                console.dir graph[node.name] if omg.opts.verbose > 1
                req = omg.jref.evaluate omg.clone(request.config), graph
                #( (delete req.payload[k] if not v? or v.length == 0 ) for k,v of req.payload ) if req.payload
                req.url = req.url+"?"+querystring.stringify req.payload if req.method is 'get' and req.payload? and Object.keys(req.payload).length
                req.url = ( if omg.opts.baseurl and not req.url.match omg.opts.baseurl then omg.opts.baseurl else '' ) + req.url
                console.log req.method+" "+req.url if omg.opts.verbose > 0
                console.dir req if omg.opts.verbose > 1
                opts = {method:req.method}
                opts.body = JSON.stringify req.payload if req.method is not 'get'
                omg.opts.requestfunc req.url, opts
                .then( (res) -> res.json() )
                .then( (json) ->
                  request.response = json
                  if request.data?
                    result = ( omg.jref.evaluate( {'_':request.data}, {response:request.response} ) )['_']
                    throw new Error({err:"could not parse '"+request.data+"' from "+nodename+"'s response",response:json}) if not result?
                    if node.type is "array"
                      node.data = []
                      schemanode = node.items[0]
                      throw new Error({err:"node '"+nodename+"' has invalid 'items' reference",node:node}) if not schemanode?
                      for item in result
                        o = omg.clone schemanode                      # clone jsonschema node
                        omg.init_node o.name,o
                        o.data = item 
                        node.data.push o
                      node.trigger 'data', node.data
                    else 
                      node.data = result
                      node.trigger 'data', node
                ).catch omg.onError
            )(graph,node,request,nodename)
            node[methodtype] = node.requestor[methodtype] # shortcut functions

      node.bindrequests(node)

    # dump client functions as string or array
    @.export_functions = (return_array_boolean) ->
      str = ''
      for name,node of omg.graph
        if node.request?
          for k,v of node.request
            if v.config?
              str += name+"."+k+"()\n"
      if return_array_boolean
        return str.replace( /()\n/g, "\n").split("\n")
      else return str

    # resolve "$ref" references in graph
    @.resolve = () ->
      omg.graph = omg.jref.resolve omg.graph

    # extend "$extend" keys in graph
    @.extend = () ->
      omg.jref.extend omg.graph

    @.init = {}

    # generate client functions from graph (after create())
    @.init.client = () ->
      omg.extend()
      omg.resolve()
      graph = omg.graph
      for nodename,node of graph
        ( (nodename,node) ->
          omg.init_node nodename,node
          omg.init_events node        
        )(nodename,node)

    @
}
