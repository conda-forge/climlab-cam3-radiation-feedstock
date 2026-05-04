REM Make flang embed flang_rt.runtime.static.lib (conda-forge ships this but not
REM the dynamic variant).
set "FFLAGS=-fms-runtime-lib=static"

REM Replicate all three libpaths flang passes when it drives a link, so MSVC
REM link.exe can find flang_rt.runtime.static.lib when meson calls it directly.
set "FLANG_LIB_BASE=%BUILD_PREFIX%\Library\lib\clang\21"
set "LIB=%FLANG_LIB_BASE%\lib\windows;%FLANG_LIB_BASE%\lib\x86_64-pc-windows-msvc;%BUILD_PREFIX%\Library\lib;%LIB%"
set "LIBPATH=%FLANG_LIB_BASE%\lib\windows;%FLANG_LIB_BASE%\lib\x86_64-pc-windows-msvc;%BUILD_PREFIX%\Library\lib;%LIBPATH%"

%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none
if errorlevel 1 exit /b 1
