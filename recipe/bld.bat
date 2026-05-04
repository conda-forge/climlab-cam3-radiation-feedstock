set "FFLAGS=-fms-runtime-lib=static"
set "CC_LD=lld-link"

REM Use Python to locate the Fortran runtime libraries and write a meson native
REM file with explicit /LIBPATH: and /defaultlib: entries that land directly on
REM the lld-link command line, bypassing LIB env-var inheritance issues.
%PYTHON% -c "import glob,os;bp=os.environ['BUILD_PREFIX'];sd=os.environ['SRC_DIR'];fdir=lambda n:[os.path.dirname(x).replace(chr(92),'/') for x in glob.glob(os.path.join(bp,'**',n),recursive=True)];d1=fdir('clang_rt.builtins-x86_64.lib');d2=fdir('flang_rt.runtime.static.lib');args=list(dict.fromkeys(['/LIBPATH:'+d for d in d1+d2]))+(['/defaultlib:clang_rt.builtins-x86_64.lib'] if d1 else []);open(os.path.join(sd,'meson_rt.ini'),'w').write('[built-in options]\nc_link_args=['+','.join(chr(39)+a+chr(39) for a in args)+']\n')"
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=--native-file=%SRC_DIR%\meson_rt.ini"
if errorlevel 1 exit /b 1
