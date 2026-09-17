import fs from 'node:fs';import os from 'node:os';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';import {createHash} from 'node:crypto';import {benchmark_json} from '../web/engine.mjs';
const groups=[
  {operation:'parse',iterations:300,inputs:['一百二','一万二千三','一亿零一万','负一千二百三十四点五六','零零三','玖仟玖佰玖拾玖万玖仟玖佰玖拾玖亿玖仟玖佰玖拾玖万玖仟玖佰玖拾玖']},
  {operation:'format',iterations:300,inputs:['0','-0.00123','1234567890123456','9999999999999999','1000100000001','123.4500']},
  {operation:'text-cn',iterations:20,inputs:['二〇二六年九月十七日，共一千二百元，增长百分之十二点五，比例三分之二，温度零下三摄氏度。'.repeat(40)]},
  {operation:'text-an',iterations:20,inputs:['2026年9月17日，共1200元，增长12.5%，比例2/3，温度3℃。'.repeat(40)]}
];
const native=spawnSync(process.env.PYTHON??'python',['tools/benchmark_reference.py'],{input:JSON.stringify(groups),encoding:'utf8',env:{...process.env,PYTHONIOENCODING:'utf-8'},windowsHide:true,timeout:120000,maxBuffer:2000000});if(native.status!==0)throw Error(native.stderr);const reference=JSON.parse(native.stdout),results=[];
for(const [index,group] of groups.entries()){
 const request=JSON.stringify(group),measure=()=>{const result=JSON.parse(benchmark_json(request));if(!result.ok)throw Error(result.error);return result;};for(let i=0;i<3;i++)measure();const runs=Array.from({length:7},measure);assert.deepEqual(runs[0].results,reference.reports[index].results);const times=runs.map(x=>x.elapsedMs).sort((a,b)=>a-b),moon=times[3],python=reference.reports[index].medianMs;
 results.push({...group,inputUtf8Bytes:group.inputs.reduce((n,s)=>n+Buffer.byteLength(s),0),outputsMatch:true,moonbitJsMedianMs:moon,pythonMedianMs:python,moonbitJsMeasurementsMs:runs.map(x=>x.elapsedMs),pythonMeasurementsMs:reference.reports[index].measurementsMs});console.log(`${group.operation}: MoonBit JS ${moon.toFixed(2)} ms / Python ${python.toFixed(2)} ms`);
}
const report={utc:new Date().toISOString(),runtime:process.version,python:reference.python,reference:reference.reference,cpu:os.cpus()[0].model,platform:process.platform,method:'3 warmups and 7 measured batches, median; same input strings and output equality; excludes JSON parsing/serialization and subprocess I/O. MoonBit returns exact decimal strings while Python cn2an returns numeric values; different runtimes and output contracts, no universal performance conclusion.',engineSha256:createHash('sha256').update(fs.readFileSync(new URL('../web/engine.mjs',import.meta.url))).digest('hex'),results};fs.writeFileSync(new URL('../evidence/performance-reference.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
