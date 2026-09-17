import sys,os,json,time,statistics,warnings
from decimal import Decimal
sys.stdin.reconfigure(encoding='utf-8');sys.stdout.reconfigure(encoding='utf-8')
if os.environ.get('CN2AN_REFERENCE_DIR'):sys.path.insert(0,os.environ['CN2AN_REFERENCE_DIR'])
import cn2an
assert cn2an.__version__=='0.5.24'
warnings.simplefilter('ignore')
reports=[]
for group in json.load(sys.stdin):
    operation=group['operation'];inputs=group['inputs'];iterations=group['iterations']
    fn={'parse':lambda s:cn2an.cn2an(s,'normal'),'format':cn2an.an2cn,'text-cn':cn2an.transform,'text-an':lambda s:cn2an.transform(s,'an2cn')}[operation]
    def measure():
        start=time.perf_counter()
        for _ in range(iterations):
            for text in inputs:fn(text)
        return (time.perf_counter()-start)*1000
    for _ in range(3):measure()
    times=[measure() for _ in range(7)]
    results=[fn(text) for text in inputs]
    if operation=='parse':
        results=[format(Decimal(str(x)),'f') for x in results]
        results=[x.rstrip('0').rstrip('.') if '.' in x else x for x in results]
    reports.append({'operation':operation,'medianMs':statistics.median(times),'measurementsMs':times,'results':results})
json.dump({'reference':'cn2an==0.5.24','python':sys.version.split()[0],'reports':reports},sys.stdout,ensure_ascii=False)
