ohmygraph = require 'ohmygraph'

api_one =
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

api_two = 
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


omg = ohmygraph.create()
omg.graph = api_one
omg.graph[k] = v for k,v of api_two

# patch by adding extra property
omg.graph["$extend"] = 
  "$ref":"#repository.properties"
  "country":{ type:"string",enum:["EN","NL","HU"] }
omg.extend()

omg.init.client()
console.dir omg.graph
console.log omg.export_functions()
process.exit()

