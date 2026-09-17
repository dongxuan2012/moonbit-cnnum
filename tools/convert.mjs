import {convert_json} from '../web/engine.mjs';
export class ConversionError extends Error {constructor(message){super(message);this.name='ConversionError';}}
export function convertNumber(request){
  if(!request||typeof request!=='object'||Array.isArray(request))throw new TypeError('Request must be an object');
  if(typeof request.input!=='string')throw new TypeError('Input must be a string to preserve exact decimal digits');
  const text=JSON.stringify(request);if(text.length>2097152)throw new RangeError('Request length limit');
  const result=JSON.parse(convert_json(text));if(!result.ok)throw new ConversionError(result.error);return result.result;
}
export function conversionResult(request){try{return {ok:true,result:convertNumber(request)}}catch(error){return {ok:false,error:error.message}}}
