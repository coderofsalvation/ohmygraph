// Generated by CoffeeScript 1.10.0
(function() {
  var fetch, jref, querystring;

  fetch = require('node-fetch');

  querystring = require('querystring');

  jref = require('json-ref-lite');

  module.exports = {
    jref: jref,
    create: function(graph, opts) {
      var omg;
      this.jref = jref;
      this.opts = opts;
      this.opts.verbose = this.opts.verbose || 0;
      this.opts.requestfunc = (typeof fetch === 'function' ? fetch : function() {
        return window.fetch.apply(window, arguments);
      });
      omg = this;
      this.onError = (function(_this) {
        return function() {
          console.error("ohmygraph exception: ");
          return console.dir(arguments);
        };
      })(this);
      this.onWarning = function(err) {
        console.error("ohmygraph warning: ");
        if (err != null) {
          return console.log(JSON.stringify(err, null, 2));
        }
      };
      this.clone = function(obj) {
        var key, temp;
        if (obj === null || typeof obj !== 'object' || typeof obj === 'function') {
          return obj;
        }
        temp = obj.constructor();
        for (key in obj) {
          temp[key] = this.clone(obj[key]);
        }
        return temp;
      };
      this.graph = this.jref.resolve(graph);
      this.get = function(node) {
        if (!this.graph[node] || (this.graph[node].properties == null)) {
          return this.onError({
            err: "node " + node + " does not exist"
          });
        }
        return this.graph[node].properties;
      };
      this.init_events = function(node) {
        node.listeners = {};
        node.on = function(event, cb) {
          if (node.listeners[event] == null) {
            node.listeners[event] = [];
          }
          return node.listeners[event].push(cb);
        };
        return node.trigger = function(event, data) {
          var handler, i, len, ref, results;
          if (node.listeners[event] == null) {
            return;
          }
          if (omg.opts.verbose > 0) {
            console.log(node.name + ".on " + event + " (" + node.listeners[event].length + " listeners)");
          }
          if (node.listeners[event] != null) {
            ref = node.listeners[event];
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
              handler = ref[i];
              results.push(handler(data));
            }
            return results;
          }
        };
      };
      this.init_node = function(nodename, node) {
        node.name = nodename;
        node.clone = function() {
          return omg.clone(node);
        };
        node.set = function(key, value) {
          return node.data[key] = value;
        };
        node.populate = function(properties) {
          var results, x, y;
          if (properties != null) {
            results = [];
            for (x in properties) {
              y = properties[x];
              results.push(node.set(x, y, node));
            }
            return results;
          }
        };
        node.on = function(event, cb) {
          return omg.graph[node.name].on(event, cb);
        };
        node.trigger = function(event, data) {
          return omg.graph[node.name].trigger(event, data);
        };
        node.bindrequests = function(node) {
          var methodtype, ref, request, results;
          if (node.request != null) {
            node.requestor = {};
            ref = node.request;
            results = [];
            for (methodtype in ref) {
              request = ref[methodtype];
              node.requestor[methodtype] = (function(graph, node, request, nodename) {
                return function(properties) {
                  var req;
                  if (properties != null) {
                    alert("todo");
                  }
                  if (omg.opts.verbose > 1) {
                    console.dir(graph[node.name]);
                  }
                  req = omg.jref.evaluate(omg.clone(request.config), graph);
                  if (req.method === 'get' && (req.payload != null) && Object.keys(req.payload).length) {
                    req.url = req.url + "?" + querystring.stringify(req.payload);
                  }
                  req.url = (omg.opts.baseurl && !req.url.match(omg.opts.baseurl) ? omg.opts.baseurl : '') + req.url;
                  if (omg.opts.verbose > 0) {
                    console.log(req.method + " " + req.url);
                  }
                  if (omg.opts.verbose > 1) {
                    console.dir(req);
                  }
                  opts = {
                    method: req.method
                  };
                  if (req.method === !'get') {
                    opts.body = JSON.stringify(req.payload);
                  }
                  return omg.opts.requestfunc(req.url, opts).then(function(res) {
                    return res.json();
                  }).then(function(json) {
                    var i, item, len, o, result, schemanode;
                    request.response = json;
                    if (request.data != null) {
                      result = (omg.jref.evaluate({
                        '_': request.data
                      }, {
                        response: request.response
                      }))['_'];
                      if (result == null) {
                        throw new Error({
                          err: "could not parse '" + request.data + "' from " + nodename + "'s response",
                          response: json
                        });
                      }
                      if (node.type === "array") {
                        node.data = [];
                        schemanode = node.items[0];
                        if (schemanode == null) {
                          throw new Error({
                            err: "node '" + nodename + "' has invalid 'items' reference",
                            node: node
                          });
                        }
                        for (i = 0, len = result.length; i < len; i++) {
                          item = result[i];
                          o = omg.clone(schemanode);
                          omg.init_node(o.name, o);
                          o.data = item;
                          node.data.push(o);
                        }
                        return node.trigger('data', node.data);
                      } else {
                        node.data = result;
                        return node.trigger('data', node);
                      }
                    }
                  })["catch"](omg.onError);
                };
              })(graph, node, request, nodename);
              results.push(node[methodtype] = node.requestor[methodtype]);
            }
            return results;
          }
        };
        return node.bindrequests(node);
      };
      this.export_functions = function() {
        var k, name, node, ref, ref1, str, v;
        str = '';
        ref = omg.graph;
        for (name in ref) {
          node = ref[name];
          if (node.request != null) {
            ref1 = node.request;
            for (k in ref1) {
              v = ref1[k];
              if (v.config != null) {
                str += name + "." + k + "()\n";
              }
            }
          }
        }
        return str;
      };
      this.init = {};
      this.init.client = function() {
        var node, nodename, results;
        graph = omg.graph;
        results = [];
        for (nodename in graph) {
          node = graph[nodename];
          results.push((function(nodename, node) {
            omg.init_node(nodename, node);
            return omg.init_events(node);
          })(nodename, node));
        }
        return results;
      };
      return this;
    }
  };

}).call(this);
