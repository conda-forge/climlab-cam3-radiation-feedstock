REM Make flang embed flang_rt.runtime.static.lib (conda-forge ships this but not
REM the dynamic variant).
set "FFLAGS=-fms-runtime-lib=static"

REM Use lld-link instead of MSVC link.exe: lld-link can read llvm-ar .a archives.
set "CC_LD=lld-link"

REM Dynamically locate both runtime libraries — their paths vary across conda-forge
REM environments. lld-link silently drops /defaultlib: entries it cannot find, so
REM the containing directories must be in LIB for symbol resolution to succeed.
for /f "tokens=*" %%f in ('dir /s /b "%BUILD_PREFIX%\clang_rt.builtins-x86_64.lib" 2^>nul') do set "CLANG_RT_DIR=%%~dpf"
for /f "tokens=*" %%f in ('dir /s /b "%BUILD_PREFIX%\flang_rt.runtime.static.lib" 2^>nul') do set "FLANG_RT_DIR=%%~dpf"
if defined CLANG_RT_DIR set "LIB=%CLANG_RT_DIR%;%LIB%"
if defined CLANG_RT_DIR set "LIBPATH=%CLANG_RT_DIR%;%LIBPATH%"
if defined FLANG_RT_DIR set "LIB=%FLANG_RT_DIR%;%LIB%"
if defined FLANG_RT_DIR set "LIBPATH=%FLANG_RT_DIR%;%LIBPATH%"

REM meson generates Fortran runtime flags as '-Wl,-defaultlib:...' (compiler-driver
REM format) which lld-link silently ignores. Pass clang_rt.builtins via
REM -Dc_link_args so it only reaches lld-link at link time (not flang's linker
REM detection step, which would misinterpret '/defaultlib:...' as a file path).
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=-Dc_link_args=/defaultlib:clang_rt.builtins-x86_64.lib"
if errorlevel 1 exit /b 1
