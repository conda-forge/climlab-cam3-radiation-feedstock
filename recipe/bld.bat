set "FFLAGS=-fms-runtime-lib=static"
set "CC_LD=lld-link"

REM Use Python to locate the Fortran runtime libraries and write a meson native
REM file with explicit /LIBPATH: and /defaultlib: entries that land directly on
REM the lld-link command line, bypassing LIB env-var inheritance issues.
%PYTHON% -c "import glob,os,subprocess;bp=os.environ['BUILD_PREFIX'];hp=os.environ.get('PREFIX',bp);sd=os.environ['SRC_DIR'];nm=next((x for x in [os.path.join(bp,'Library','bin','llvm-nm.exe')] if os.path.exists(x)),None);print('llvm-nm:',nm);cands=sorted(set(x for p in [bp,hp] for x in glob.glob(os.path.join(p,'**','*.lib'),recursive=True) if any(k in os.path.basename(x).lower() for k in ['clang_rt','flang_rt']))); found=[x.replace(chr(92),'/') for x in cands if nm and '__floatsitf' in subprocess.run([nm,'--defined-only',x],capture_output=True,text=True,timeout=30).stdout];print('__floatsitf found in:',found);static_r=sorted(set(x.replace(chr(92),'/') for p in [bp,hp] for x in glob.glob(os.path.join(p,'**','flang_rt.runtime.static.lib'),recursive=True) if 'dbg' not in x));static_c=sorted(set(x.replace(chr(92),'/') for p in [bp,hp] for x in glob.glob(os.path.join(p,'**','clang_rt.builtins-x86_64.lib'),recursive=True)));args=sorted(set(found+static_r+static_c[:1]));print('c_link_args:',args);open(os.path.join(sd,'meson_rt.ini'),'w').write('[built-in options]\nc_link_args=['+','.join(chr(39)+a+chr(39) for a in args)+']\n')"
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=--native-file=%SRC_DIR%\meson_rt.ini"
if errorlevel 1 exit /b 1
