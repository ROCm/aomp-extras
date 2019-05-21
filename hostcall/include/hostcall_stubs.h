
#define EXTERN extern "C" __device__

/* These are the interfaces for the device stubs */
///
EXTERN int printf( const char * , ...);
EXTERN char *  printf_alloc(uint bufsz);
EXTERN int     printf_execute(char * bufptr);
EXTERN uint32_t __strlen_max(char*instr, uint32_t maxstrlen);
EXTERN int     vector_product_zeros(int N, int*A, int*B, int*C);

typedef struct hostcall_result_s{
  ulong arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7;
} hostcall_result_t;

EXTERN hostcall_result_t hostcall_invoke(uint id,
    ulong arg0, ulong arg1, ulong arg2, ulong arg3,
    ulong arg4, ulong arg5, ulong arg6, ulong arg7);
