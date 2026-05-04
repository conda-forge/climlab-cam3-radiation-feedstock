REM Make flang embed flang_rt.runtime.static.lib (conda-forge ships this but not
REM the dynamic variant).
set "FFLAGS=-fms-runtime-lib=static"

REM Use lld-link instead of MSVC link.exe: lld-link can read llvm-ar .a archives.
set "CC_LD=lld-link"

REM Keep library search paths so lld-link can find flang and clang runtime libs.
set "FLANG_LIB_BASE=%BUILD_PREFIX%\Library\lib\clang\21"
set "LIB=%FLANG_LIB_BASE%\lib\windows;%FLANG_LIB_BASE%\lib\x86_64-pc-windows-msvc;%BUILD_PREFIX%\Library\lib;%LIB%"
set "LIBPATH=%FLANG_LIB_BASE%\lib\windows;%FLANG_LIB_BASE%\lib\x86_64-pc-windows-msvc;%BUILD_PREFIX%\Library\lib;%LIBPATH%"

REM meson generates Fortran runtime flags as '-Wl,-defaultlib:...' (compiler-driver
REM format) which lld-link silently ignores, leaving __floatsitf etc. unresolved.
REM Pass clang_rt.builtins via -Dc_link_args instead of LDFLAGS: meson applies
REM c_link_args only at link time, so it never reaches flang's linker-detection step
REM (which would misinterpret '/defaultlib:...' as a file path and abort).
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=-Dc_link_args=/defaultlib:clang_rt.builtins-x86_64.lib"
if errorlevel 1 exit /b 1
