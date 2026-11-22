const http=require('http'),fs=require('fs');
const T=(()=>{try{return fs.readFileSync('/eyes.txt','utf8')}catch(e){return 'no eyes.txt'}})();
http.createServer((q,r)=>{
 if(q.url==='/api/health'){r.writeHead(200,{'content-type':'application/json'});r.end('{"status":"ok"}');return;}
 if(q.url==='/rerun'){let o='';try{o=fs.execSync('sh /tmp/eyesk.sh && cat /tmp/k.txt',{timeout:14000}).toString()}catch(e){o='ERR '+String(e).slice(0,200)}r.writeHead(200,{'content-type':'text/plain'});r.end(o);return;}
 r.writeHead(200,{'content-type':'text/plain'});r.end(T);
}).listen(3000);
