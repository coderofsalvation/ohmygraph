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
    properties:
      id: { type:"number", default: 12 }
      name: { type: "string", default: 'John Doe' }
      category: { type: "string", default: 'amsterdam' }
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
          url: '/book'
          payload:
            'fullname': '{book.name}'
            'firstname': '{firstname}'
            'category': '{book.category}'
          schema: {"$ref":"#/book"}
        data: "{response}"


omg = ohmygraph.create graph, {baseurl: "https://api.github.com",verbose:2}
console.log omg.export_functions()
process.exit()

omg.init.client()
client = omg.graph

client.repositories.on 'data', (repositories) ->
  console.log "on repositories"
  repositories[0].get()

client.repository.on 'data', (repository) ->
  console.log "on repository"
  console.dir repository

client.repositories.get()
#client.repositories.get {q:"foo"}


#omg.graph.repository.data.get (data) ->
#  console.log "\n->receive: "+data
