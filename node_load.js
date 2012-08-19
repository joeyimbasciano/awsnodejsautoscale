// Nodejs script to simulate generating load on a server. 
// Accepts a GET parameter 'count' specifying how many 64byte blocks to write
// using dd. The higher the count the longer the load will last.
// 
// Example: http://ec2-23-20-88-195.compute-1.amazonaws.com:8000/?count=100000
var http = require('http');
var spawn = require('child_process').spawn;
var url = require('url');

var server = http.createServer(function (request, response) {
  // skip favicon request
  if(request.url === '/favicon.ico') {
    response.writeHead(200, {'Content-Type': 'image/x-icon'} );
    response.end();
    return;
  }

  // Parse query for count, default to 1 if not found to be safe.
  query = (url.parse(request.url, true).query);
  if(query.count){
    count = 'count='+query.count;
  }
  else {
    count = 'count=1';
  }

  // Spawn dd and write the response to the client.
  spawn('dd', ['if=/dev/urandom', 'of=/tmp/foo.txt', count, 'bs=64']);
  response.writeHead(200, {"Content-Type": "text/plain"});
  response.end("Wrote " + count + " blocks.");
});

// Listen on port 8000
server.listen(8000);
