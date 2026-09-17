import http from 'node:http';import {pathToFileURL} from 'node:url';import {conversionResult} from './convert.mjs';
export function createConversionServer(){
  return http.createServer({requestTimeout:15000,headersTimeout:10000,keepAliveTimeout:1000},async(req,res)=>{
    const send=(status,result)=>{if(res.destroyed||res.writableEnded)return;res.writeHead(status,{'content-type':'application/json; charset=utf-8','cache-control':'no-store'});res.end(JSON.stringify(result));};
    if(req.method==='GET'&&req.url==='/health'){send(200,{ok:true,version:'0.4.0'});return;}
    if(req.url!=='/convert'){send(404,{ok:false,error:'Not found'});req.resume();return;}
    if(req.method!=='POST'){send(405,{ok:false,error:'POST required'});req.resume();return;}
    if(req.headers['content-type']?.split(';')[0].trim()!=='application/json'){send(415,{ok:false,error:'application/json required'});req.resume();return;}
    const declared=Number(req.headers['content-length']??0);if(declared>2097152){send(413,{ok:false,error:'Request exceeds 2 MiB'});req.resume();return;}
    try{let size=0;const chunks=[];for await(const chunk of req){size+=chunk.length;if(size>2097152){send(413,{ok:false,error:'Request exceeds 2 MiB'});req.resume();return;}chunks.push(chunk);}
      const text=new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(chunks));const result=conversionResult(JSON.parse(text));send(result.ok?200:422,result);
    }catch(error){send(400,{ok:false,error:error.message});}
  });
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
  const port=Number(process.env.PORT??8781);if(!Number.isInteger(port)||port<0||port>65535)throw Error('Invalid PORT');
  const server=createConversionServer();server.listen(port,'127.0.0.1',()=>console.log(JSON.stringify({url:`http://127.0.0.1:${server.address().port}`,endpoint:'/convert'})));
  for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>server.close(()=>process.exit(0)));
}
