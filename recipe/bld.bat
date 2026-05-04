set "FFLAGS=-fms-runtime-lib=static"
set "CC_LD=lld-link"

REM Locate Fortran runtime libraries so lld-link can find them via the LIB search
REM path. lld-link silently skips /defaultlib entries it cannot find, so the
REM directories must be in LIB for symbol resolution to succeed.
dir /s /b "%BUILD_PREFIX%\clang_rt.builtins-x86_64.lib" > "%TEMP%\rt_lib1.txt" 2>nul
dir /s /b "%BUILD_PREFIX%\flang_rt.runtime.static.lib" > "%TEMP%\rt_lib2.txt" 2>nul
for /f "usebackq tokens=*" %%f in ("%TEMP%\rt_lib1.txt") do set "CLANG_RT_DIR=%%~dpf"
for /f "usebackq tokens=*" %%f in ("%TEMP%\rt_lib2.txt") do set "FLANG_RT_DIR=%%~dpf"
if defined CLANG_RT_DIR set "LIB=%CLANG_RT_DIR%;%LIB%"
if defined CLANG_RT_DIR set "LIBPATH=%CLANG_RT_DIR%;%LIBPATH%"
if defined FLANG_RT_DIR set "LIB=%FLANG_RT_DIR%;%LIB%"
if defined FLANG_RT_DIR set "LIBPATH=%FLANG_RT_DIR%;%LIBPATH%"

REM meson generates -Wl,-defaultlib:... flags that lld-link cannot parse.
REM Pass clang_rt.builtins via -Dc_link_args so it reaches lld-link at link time
REM without going through flang linker detection, which rejects /defaultlib:...
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=-Dc_link_args=/defaultlib:clang_rt.builtins-x86_64.lib"
if errorlevel 1 exit /b 1
