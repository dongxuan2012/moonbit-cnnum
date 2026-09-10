import config from './config.mjs';
import {convert} from './engine.mjs';
const $=id=>document.getElementById(id);
const examples={money:'1234.05','parse-money':'壹仟贰佰叁拾肆元零伍分',decimal:'-0.0012300','parse-decimal':'负零点零零一二三零零',digits:'002026','parse-digits':'零零二零二六','parse-integer':'一万零一'};
$('title').textContent=config.title+' · 0.3.0';
$('scope').textContent='中文整数、精确小数、逐字数字和人民币金额互转。小数全程保留文本精度。';
$('limits').textContent='整数绝对值最大 9,999,999,999,999,999；小数最多 64 位。金额精确到分；不猜测口语省略，不自动舍入。';
function execute(){
 try {
  const output=convert($('mode').value,$('input').value,$('financial').checked,$('variants').checked);
  const ok=!output.startsWith('ERROR:');
  $('output').textContent=output;$('output').className=ok?'':'error';
  $('status').textContent=ok?'转换完成':'请检查输入格式';
 } catch(error) { $('output').textContent=String(error);$('output').className='error'; }
}
function reset(){ $('input').value=examples[$('mode').value];execute(); }
$('run').onclick=execute;$('reset').onclick=reset;$('mode').onchange=reset;
$('financial').onchange=execute;$('variants').onchange=execute;reset();
