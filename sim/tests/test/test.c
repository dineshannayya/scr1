
#define SC_SIM_OUTPORT (0xf0000000)
#define uint32_t  long

//#include <stdio.h>
//#include <stdlib.h>
//#include "coremark.h"
//#include "core_portme.h"
//#include "riscv_csr_encoding.h"
#include "sc_test.h"


int main()
{


    //ee_printf("CoreMark 1.0\n");

    volatile long *out_ptr = (volatile long*)SC_SIM_OUTPORT;
    //printf("Hello");
    *out_ptr = 0xAABBCCDD;
    *out_ptr = 0xBBCCDDEE;
    *out_ptr = 0xCCDDEEFF;
    *out_ptr = 0xDDEEFF00;

}
