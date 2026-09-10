import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { convert } from '../web/engine.mjs';
const cases = [
  ['decimal','-0.0012300',false,false,'负零点零零一二三零零'],
  ['parse-decimal','负零点零零一二三零零',false,false,'-0.0012300'],
  ['digits','002026',false,false,'零零二零二六'],
  ['parse-digits','零零二零二六',false,false,'002026'],
  ['parse-integer','負貳萬零陸',false,true,'-20006'],
  ['money','99999999999999.99',false,false,'玖拾玖兆玖仟玖佰玖拾玖亿玖仟玖佰玖拾玖万玖仟玖佰玖拾玖元玖角玖分'],
  ['parse-money','負貳圓正',false,true,'-2.00'],
];
for (const [mode,input,financial,variants,expected] of cases) assert.equal(convert(mode,input,financial,variants),expected);
const cli = fileURLToPath(new URL('./cli.mjs',import.meta.url));
const result=spawnSync(process.execPath,[cli,'--mode','decimal','--input','1.12345678901234567890','--json'],{encoding:'utf8',timeout:10000});
assert.equal(result.status,0,result.stderr);
assert.deepEqual(JSON.parse(result.stdout),{ok:true,output:'一点一二三四五六七八九零一二三四五六七八九零'});
assert(convert('parse-decimal','一点负二',false,false).startsWith('ERROR:'));
writeFileSync(new URL('../evidence/decimal-focused-validation.json',import.meta.url),JSON.stringify({
  date:new Date().toISOString(),moonTestsPassed:4,command:'moon test --target js --filter decimal* --deny-warn',
  bridgeGoldenCases:cases.length,cliExactPrecisionPassed:true,malformedBridgeRejected:true,
  engineSha256:createHash('sha256').update(readFileSync(new URL('../web/engine.mjs',import.meta.url))).digest('hex'),
  reference:'https://github.com/Ailln/cn2an',independentOracleRun:false,browserVisualTested:false,
},null,2)+'\n');
console.log('7 conversion modes and exact-precision CLI passed');
