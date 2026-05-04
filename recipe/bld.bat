REM Make flang embed flang_rt.runtime.static.lib (conda-forge ships this but not
REM the dynamic variant).
set "FFLAGS=-fms-runtime-lib=static"

REM Use lld-link instead of MSVC link.exe: lld-link can read llvm-ar .a archives.
set "CC_LD=lld-link"

REM clang_rt.builtins is at lib\clang\21\lib\windows\ (confirmed, no Library\ prefix).
REM flang_rt.runtime.static.lib location is uncertain; search all plausible paths.
set "CLANG_RT_DIR=%BUILD_PREFIX%\lib\clang\21\lib\windows"
set "LIB=%CLANG_RT_DIR%;%BUILD_PREFIX%\Library\lib\clang\21\lib\windows;%BUILD_PREFIX%\Library\lib;%BUILD_PREFIX%\lib;%LIB%"
set "LIBPATH=%CLANG_RT_DIR%;%BUILD_PREFIX%\Library\lib\clang\21\lib\windows;%BUILD_PREFIX%\Library\lib;%BUILD_PREFIX%\lib;%LIBPATH%"

REM meson generates Fortran runtime flags as '-Wl,-defaultlib:...' (compiler-driver
REM format) which lld-link silently ignores, leaving __floatsitf etc. unresolved.
REM Pass clang_rt.builtins via -Dc_link_args instead of LDFLAGS: meson applies
REM c_link_args only at link time, so it never reaches flang's linker-detection step
REM (which would misinterpret '/defaultlib:...' as a file path and abort).
%PYTHON% -m pip install . --no-build-isolation --no-deps -vv -Csetup-args=-Db_vscrt=none "-Csetup-args=-Dc_link_args=/defaultlib:clang_rt.builtins-x86_64.lib"
if errorlevel 1 exit /b 1
