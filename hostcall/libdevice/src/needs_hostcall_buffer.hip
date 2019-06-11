///
/// needs_hostcall_buffer.hip:
///
/// This source module is only to provide a definition for the global variable needs_hostcall_buffer
/// It should not be linked with the device stubs because we use the unresolved declaration
/// To detect that services are required.  This is done in the clang-build-select-link tool. 
/// See ClangBuildSelectLink.cpp.  That tool will link in this definition to avoid the unresolved 
/// declaration.  At runtime, atmi will look for this symbol and if found it will allocate 
/// the buffer and start a services consumer thread. 

__attribute__((device)) unsigned int needs_hostcall_buffer;
