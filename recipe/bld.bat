set "FFLAGS=-fms-runtime-lib=static"
set "CC_LD=lld-link"

REM Compile a stub for __floatsitf (int32->binary128), missing from the Windows
REM build of clang_rt.builtins because MSVC mode excludes TFmode builtins.
REM On Windows x64 MSVC ABI a 16-byte struct return uses sret: RCX=result ptr,
REM EDX=input, which matches what LLVM generates when calling __floatsitf.
%PYTHON% -c "import os,subprocess as sp,glob;sd=os.environ['SRC_DIR'];bp=os.environ['BUILD_PREFIX'];hp=os.environ.get('PREFIX',bp);src=os.path.join(sd,'floatsitf_stub.c');obj=os.path.join(sd,'floatsitf_stub.obj');open(src,'w').write('#include <stdint.h>\ntypedef struct{uint64_t lo;uint64_t hi;}fp128;\nfp128 __floatsitf(int a){\nfp128 r={0,0};\nif(!a)return r;\nunion{double d;unsigned long long u;}p;\np.d=(double)a;\nunsigned long long u=p.u;\nunsigned long long s=u&0x8000000000000000ULL;\nunsigned long long e=((u>>52)&0x7FFULL)+15360ULL;\nunsigned long long m=u&0x000FFFFFFFFFFFFFULL;\nr.hi=s|(e<<48)|(m>>4);\nr.lo=(m&15ULL)<<60;\nreturn r;}\n');r=sp.run(['cl.exe','/O2','/nologo','/c',src,'/Fo'+obj],capture_output=True,text=True,cwd=sd);print(r.returncode,r.stdout,r.stderr);fp=lambda n:sorted(set(x.replace(chr(92),'/') for p in [bp,hp] for x in glob.glob(os.path.join(p,'**',n),recursive=True)));sr=fp('flang_rt.runtime.static.lib');sc=fp('clang_rt.builtins-x86_64.lib');args=([obj.replace(chr(92),'/')] if os.path.exists(obj) else [])+[x for x in sr if 'dbg' not in x][:1]+sc[:1];print('c_link_args:',args);open(os.path.join(sd,'meson_rt.ini'),'w').write('[built-in options]\nc_link_args=['+','.join(chr(39)+a+chr(39) for a in args)+']\n')"
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=--native-file=%SRC_DIR%\meson_rt.ini"
if errorlevel 1 exit /b 1
