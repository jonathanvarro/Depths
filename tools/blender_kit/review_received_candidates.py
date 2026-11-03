"""Reuse the established garment checks/exports/captures in an isolated version.

--mode check | export | capture. Existing garment/review masters stay untouched.
"""
import sys,argparse
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).parent))
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1/animation-requests-v1/received-v1/candidates-v1'
def main():
    p=argparse.ArgumentParser();p.add_argument('--mode',required=True,choices=['check','export','capture']);opt=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    if opt.mode=='check':
        import check_garments as runner;runner.OUT=OUT;runner.main()
    elif opt.mode=='export':
        import export_check_garments as runner;runner.OUT=OUT;runner.main()
    else:
        import capture_garments as runner;runner.OUT=OUT;runner.REVIEW=OUT/'review';sys.argv=['capture_garments.py','--matrix','--motion'];runner.main()
if __name__=='__main__':main()
