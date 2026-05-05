set "FFLAGS=-fms-runtime-lib=static"
set "CC_LD=lld-link"

REM Compile a stub for __floatsitf (int32->binary128), missing from the Windows
REM build of clang_rt.builtins because MSVC mode excludes TFmode builtins.
REM On Windows x64 MSVC ABI a 16-byte struct return uses sret: RCX=result ptr,
REM EDX=input, which matches what LLVM generates when calling __floatsitf.
%PYTHON% -c "import os,subprocess as sp,glob;sd=os.environ['SRC_DIR'];bp=os.environ['BUILD_PREFIX'];hp=os.environ.get('PREFIX',bp);src=os.path.join(sd,'floatsitf_stub.c');obj=os.path.join(sd,'floatsitf_stub.obj');cclang=next((x for x in [os.path.join(bp,'Library','bin','clang-cl.exe')] if os.path.exists(x)),None);print('clang-cl:',cclang);open(src,'w').write('__float128 __floatsitf(int a){return(__float128)a;}\n' if cclang else '#include <stdint.h>\ntypedef struct{uint64_t lo;uint64_t hi;}fp128;\nfp128 __floatsitf(int a){fp128 r={0,0};if(!a)return r;union{double d;unsigned long long u;}p;p.d=(double)a;unsigned long long u=p.u,s=u&0x8000000000000000ULL,e=((u>>52)&0x7FFULL)+15360ULL,m=u&0x000FFFFFFFFFFFFFULL;r.hi=s|(e<<48)|(m>>4);r.lo=(m&15ULL)<<60;return r;}\n');cc=cclang if cclang else 'cl.exe';r=sp.run([cc,'/O2','/nologo','/c',src,'/Fo'+obj],capture_output=True,text=True,cwd=sd);print(r.stdout,r.stderr);fp=lambda n:sorted(set(x.replace(chr(92),'/') for p in [bp,hp] for x in glob.glob(os.path.join(p,'**',n),recursive=True)));sr=fp('flang_rt.runtime.static.lib');sc=fp('clang_rt.builtins-x86_64.lib');args=([obj.replace(chr(92),'/')] if os.path.exists(obj) else [])+[x for x in sr if 'dbg' not in x][:1]+sc[:1];print('c_link_args:',args);open(os.path.join(sd,'meson_rt.ini'),'w').write('[built-in options]\nc_link_args=['+','.join(chr(39)+a+chr(39) for a in args)+']\n')"
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=--native-file=%SRC_DIR%\meson_rt.ini"
if errorlevel 1 exit /b 1
