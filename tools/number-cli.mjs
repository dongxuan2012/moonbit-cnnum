import fs from 'node:fs';import {once} from 'node:events';import {conversionResult} from './convert.mjs';
const args=process.argv.slice(2),request={},options={};
const names={'--mode':'mode','--direction':'direction','--rounding':'rounding','--yuan':'yuan','--whole-suffix':'wholeSuffix','--prefix':'prefix'};
const flags={'--direct':'direct','--zero-yuan':'zeroYuan','--parentheses':'parentheses'};
async function output(value){if(!process.stdout.write(value))await once(process.stdout,'drain');}
async function* inputLines(stream){const decoder=new TextDecoder('utf-8',{fatal:true});let buffer='';for await(const chunk of stream){buffer+=decoder.decode(chunk,{stream:true});let end;while((end=buffer.indexOf('\n'))>=0){if(end>2097152)throw Error('JSONL line length limit');yield buffer.slice(0,end);buffer=buffer.slice(end+1);}if(buffer.length>2097152)throw Error('JSONL line length limit');}buffer+=decoder.decode();if(buffer.length>2097152)throw Error('JSONL line length limit');if(buffer)yield buffer;}
try{
  if(args.includes('--help')||!args.length){await output('Usage: node tools/number-cli.mjs cn2an|an2cn|transform|spans|currency [--input TEXT | --file PATH] [--json]\n  --mode strict|normal|smart|direct|low|up|rmb; --direction cn2an|an2cn; --direct\n  Currency: --rounding reject|truncate|half-up --zero-yuan --yuan TEXT --whole-suffix TEXT --prefix TEXT --parentheses\n  jsonl [--file PATH] streams one request/result per line. Text stdin is used otherwise.\nExit: 0 success, 2 rejected conversion or batch record, 1 host/argument/UTF-8 error.\n');process.exit(0);}
  request.operation=args.shift();if(!['cn2an','an2cn','transform','spans','currency','jsonl'].includes(request.operation))throw Error('Unknown operation');
  for(let i=0;i<args.length;i++){
    const arg=args[i];if(arg==='--json'){options.json=true;continue;}
    if(flags[arg]){request[flags[arg]]=true;continue;}
    if(names[arg]||arg==='--input'||arg==='--file'){
      if(++i>=args.length)throw Error('Missing option value: '+arg);const value=args[i];
      if(names[arg]){if(request[names[arg]]!==undefined)throw Error('Duplicate option: '+arg);request[names[arg]]=value;}
      else{if(options.input!==undefined||options.file!==undefined)throw Error('Select one input source');options[arg==='--input'?'input':'file']=value;}
    }else throw Error('Unknown option: '+arg);
  }
  if(request.operation==='jsonl'){
    if(options.input!==undefined||Object.keys(request).length!==1)throw Error('jsonl accepts --file or stdin only');
    const stream=options.file?fs.createReadStream(options.file,{highWaterMark:65536}):process.stdin;
    try{for await(const line of inputLines(stream)){if(!line.trim())continue;let result;try{result=conversionResult(JSON.parse(line));}catch(error){result={ok:false,error:error.message}}if(!result.ok)process.exitCode=2;await output(JSON.stringify(result)+'\n');}}finally{if(options.file)stream.destroy();}
  }else{
    let input=options.input;
    if(input===undefined){const stream=options.file?fs.createReadStream(options.file,{highWaterMark:65536}):process.stdin;let size=0;const chunks=[];try{for await(const chunk of stream){size+=chunk.length;if(size>2097152)throw Error('Input exceeds 2 MiB');chunks.push(chunk);}}finally{if(options.file)stream.destroy();}input=new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(chunks));}
    if(Buffer.byteLength(input)>2097152)throw Error('Input exceeds 2 MiB');
    const result=conversionResult({...request,input});if(!result.ok)process.exitCode=2;
    await output(options.json||typeof result.result!=='string'?JSON.stringify(result)+'\n':result.result+'\n');
  }
}catch(error){process.stderr.write(JSON.stringify({ok:false,error:error.message})+'\n');process.exitCode=1;}
