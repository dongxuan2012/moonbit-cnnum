import fs from 'node:fs';
import {run,convert} from '../web/engine.mjs';
const args=process.argv.slice(2);let input, json=false, mode, financial=false, variants=false;
try {
 for(let i=0;i<args.length;i++){
  const a=args[i];
  if(a==='--help'){process.stdout.write('Usage: node tools/cli.mjs [--input TEXT | --file PATH] [--json] [--mode MODE] [--financial] [--variants]\nModes: decimal, parse-decimal, digits, parse-digits, parse-integer, money, parse-money.\nWithout --input/--file, reads UTF-8 stdin. Exit: 0 success, 2 invalid input, 1 host error.\n');process.exit(0)}
  else if(a==='--json')json=true;
  else if(a==='--financial')financial=true;
  else if(a==='--variants')variants=true;
  else if(a==='--mode'){if(mode!==undefined||i+1>=args.length)throw new Error('Expected one mode');mode=args[++i]}
  else if(a==='--input'||a==='--file'){
   if(input!==undefined||i+1>=args.length)throw new Error('Exactly one input source is required');
   const value=args[++i];
   if(a==='--file'){if(fs.statSync(value).size>2097152)throw new Error('Input exceeds 2 MiB');input=fs.readFileSync(value,'utf8')}else input=value;
  }else throw new Error('Unknown argument: '+a);
 }
 if(input===undefined){let size=0;const chunks=[];for await(const chunk of process.stdin){size+=chunk.length;if(size>2097152)throw new Error('Input exceeds 2 MiB');chunks.push(chunk)}input=Buffer.concat(chunks).toString('utf8')}
 if(Buffer.byteLength(input)>2097152)throw new Error('Input exceeds 2 MiB');
 const output=mode!==undefined||financial||variants?convert(mode??'money',input,financial,variants):run(input),ok=!output.startsWith('ERROR:');
 process.stdout.write(json?JSON.stringify({ok,output})+'\n':output+(output.endsWith('\n')?'':'\n'));
 process.exitCode=ok?0:2;
}catch(e){process.stderr.write(JSON.stringify({ok:false,error:String(e.message||e)})+'\n');process.exitCode=1}
