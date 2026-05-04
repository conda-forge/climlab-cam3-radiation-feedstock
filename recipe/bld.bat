set "FFLAGS=-fms-runtime-lib=static"
set "CC_LD=lld-link"

REM Use Python to locate the Fortran runtime libraries and write a meson native
REM file with explicit /LIBPATH: and /defaultlib: entries that land directly on
REM the lld-link command line, bypassing LIB env-var inheritance issues.
%PYTHON% -c "import glob,os;bp=os.environ['BUILD_PREFIX'];hp=os.environ.get('PREFIX',bp);sd=os.environ['SRC_DIR'];libs=sorted(set(x.replace(chr(92),'/') for p in [bp,hp] for x in glob.glob(os.path.join(p,'**','x86_64-pc-windows-msvc','*.lib'),recursive=True)));open(os.path.join(sd,'meson_rt.ini'),'w').write('[built-in options]\nc_link_args=['+','.join(chr(39)+a+chr(39) for a in libs)+']\n')"
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=--native-file=%SRC_DIR%\meson_rt.ini"
if errorlevel 1 exit /b 1
