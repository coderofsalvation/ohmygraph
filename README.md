<center><img src="https://raw.githubusercontent.com/coderofsalvation/ohmygraph/master/.npm/logo.png" width="40%"/></center>

# Usage:

    npm install ohmygraph

or in the browser (6k when gzipped):

    <script type="text/javascript" src="ohmygraph.min.js"></script> 

# Example: github api

    ohmygraph = require 'ohmygraph'

    graph =
      repositories:
        type: "array"
        items: [{"$ref":"#/repository"}]
        data: { sort:'stars',q:'ohmy',order:'desc' }
        request:
          get:
            config:
              method: 'get'
              url: '/search/repositories'
              payload:
                q: '{repositories.data.q}'
                sort: '{repositories.data.sort}'
                order: '{repositories.data.order}'
            data: "{response.items}"
      repository:
        type: "object"
        properties: { ..... }
        data: {}
        request:
          get:
            config:
              method: 'get'
              url: '/repos/{repository.data.full_name}'
              payload: {}
            data: "{response}"
          post:
            type: "request"
            config:
              method: "post"
              url: '/repos/{repository.data.full_name}'
              payload:
                'full_name': '{repository.data.full_name}'


    omg = ohmygraph.create graph, {baseurl: "https://api.github.com",verbose:2}
    omg.init.client()
    client = omg.graph

    client.repositories.on 'data', (repositories) ->
      console.log "on repositories"
      repositories[0].get()

    client.repository.on 'data', (repository) ->
      console.log "on repository"
      console.dir repository

    # lets request data!
    client.repositories.get()
    client.repositories.get {q:"foo"}

# Api 

init.client()
> init client from created graph(after create())

get(node)
> get node with name x

graph = jref.resolve graph
> access your resolved graph here

clone(obj)
> deep clone object utility function

onWarning(err)
> customizable warning function

onError()
> customizable error/catch function

create(graph,opts)
> create and resolve graph

yournode.bindrequests(node)
> autobind client requesthandlers on node

yournode.trigger(event,data)
> trigger an event on your nodeyournode.trigger('foo',{data:'bar'})

yournode.on(event,cb)
> register an event on your nodeyournode.on( 'foo', function(){} )

yournode.clone   ()
> call clone() on a node to keep the original intact 

