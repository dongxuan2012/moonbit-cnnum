import config from './config.mjs';
import {convert,convert_json} from './engine.mjs';
const $=id=>document.getElementById(id);
const examples={money:'1234.05','parse-money':'壹仟贰佰叁拾肆元零伍分',decimal:'-0.0012300','parse-decimal':'负零点零零一二三零零',digits:'002026','parse-digits':'零零二零二六','parse-integer':'一万零一',smart:'1万2千3百45',normal:'一万二',strict:'一亿零一万',standard:'1000100000001',rmb:'0.15',currency:'-1234.05','text-cn':'二〇二六年九月十七日，增长百分之十二点五，温度零下三摄氏度。','text-an':'2026年9月17日，完成12.5%，比例2/3。'};
$('title').textContent=config.title+' · '+config.version;
$('scope').textContent='混合数字、口语省略、日期、分数、百分比、温度与金额转换。精确文本运算，保留原有规范接口。';
$('limits').textContent='整数最多 16 位，小数最多 64 位；句子转换按词法规则处理，可能转换成语中的数字。金额舍入需显式选择。';
function execute(){
 try {
  const currency=$('mode').value==='currency';$('currency-options').hidden=!currency;
  const result=currency?JSON.parse(convert_json(JSON.stringify({operation:'currency',input:$('input').value,prefix:$('currency-prefix').value,yuan:$('currency-yuan').value,rounding:$('currency-rounding').value,zeroYuan:$('zero-yuan').checked,parentheses:$('parentheses').checked}))):null;
  const output=currency?(result.ok?result.result:'ERROR: '+result.error):convert($('mode').value,$('input').value,$('financial').checked,$('variants').checked);
  const ok=!output.startsWith('ERROR:');
  $('output').textContent=output;$('output').className=ok?'':'error';
  $('status').textContent=ok?'转换完成':'请检查输入格式';
 } catch(error) { $('output').textContent=String(error);$('output').className='error'; }
}
function reset(){ $('input').value=examples[$('mode').value];execute(); }
$('run').onclick=execute;$('reset').onclick=reset;$('mode').onchange=reset;
$('financial').onchange=execute;$('variants').onchange=execute;reset();
for(const id of ['currency-prefix','currency-yuan','currency-rounding','zero-yuan','parentheses'])$(id).onchange=execute;
