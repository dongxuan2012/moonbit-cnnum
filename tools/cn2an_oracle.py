"""Independent adapter to the unmodified pinned PyPI distribution; test only."""
import sys, os, json, warnings, hashlib, importlib.metadata
from pathlib import Path
from decimal import Decimal
sys.stdin.reconfigure(encoding='utf-8')
sys.stdout.reconfigure(encoding='utf-8')
if os.environ.get('CN2AN_REFERENCE_DIR'):
    sys.path.insert(0, os.environ['CN2AN_REFERENCE_DIR'])
import cn2an
assert cn2an.__version__ == '0.5.24', cn2an.__version__

def call(request):
    try:
        with warnings.catch_warnings():
            warnings.simplefilter('ignore')
            op = request['operation']
            if op == 'transform':
                result = cn2an.transform(request['input'], request.get('direction','cn2an'), direct=request.get('direct',False))
            elif op == 'cn2an':
                result = cn2an.cn2an(request['input'], request.get('mode','strict'))
                if not isinstance(result,str):
                    result = format(Decimal(str(result)), 'f')
                    if '.' in result: result = result.rstrip('0').rstrip('.')
                    if result == '-0': result = '0'
            elif op == 'an2cn':
                result = cn2an.an2cn(request['input'], request.get('mode','low'))
            else: raise ValueError('Unknown operation')
        return {'ok':True,'result':result}
    except Exception as error:
        return {'ok':False,'type':type(error).__name__}

request=json.load(sys.stdin)
package=Path(cn2an.__file__).parent
fingerprints={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(package.glob('*.py'))}
json.dump({'reference':'cn2an==0.5.24','python':sys.version.split()[0], 'proces':importlib.metadata.version('proces'),'packageSha256':fingerprints,'results':[call(r) for r in request]},sys.stdout,ensure_ascii=False)
