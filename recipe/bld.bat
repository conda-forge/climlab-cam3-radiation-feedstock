setlocal EnableDelayedExpansion

REM Make flang embed flang_rt.runtime.static.lib (conda-forge ships this but not
REM the dynamic variant).
set "FFLAGS=-fms-runtime-lib=static"

REM Use lld-link instead of MSVC link.exe: lld-link can read llvm-ar .a archives.
set "CC_LD=lld-link"

REM clang_rt.builtins is confirmed at lib\clang\21\lib\windows\ (no Library\ prefix,
REM as seen in meson's auto-generated flag path from the build log).
set "CLANG_RT_DIR=%BUILD_PREFIX%\lib\clang\21\lib\windows"
set "LIB=%CLANG_RT_DIR%;%BUILD_PREFIX%\Library\lib;%LIB%"
set "LIBPATH=%CLANG_RT_DIR%;%BUILD_PREFIX%\Library\lib;%LIBPATH%"

REM flang_rt.runtime.static.lib location varies; search the whole build prefix and
REM add whatever directory contains it to the linker library search path.
for /f "tokens=*" %%f in ('dir /s /b "%BUILD_PREFIX%\flang_rt.runtime.static.lib" 2^>nul') do set "FLANG_RT_DIR=%%~dpf"
if defined FLANG_RT_DIR set "LIB=!FLANG_RT_DIR!;!LIB!"
if defined FLANG_RT_DIR set "LIBPATH=!FLANG_RT_DIR!;!LIBPATH!"

REM meson generates Fortran runtime flags as '-Wl,-defaultlib:...' (compiler-driver
REM format) which lld-link silently ignores, leaving __floatsitf etc. unresolved.
REM Pass clang_rt.builtins via -Dc_link_args instead of LDFLAGS: meson applies
REM c_link_args only at link time, so it never reaches flang's linker-detection step
REM (which would misinterpret '/defaultlib:...' as a file path and abort).
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=-Dc_link_args=/defaultlib:clang_rt.builtins-x86_64.lib"
if errorlevel 1 exit /b 1
