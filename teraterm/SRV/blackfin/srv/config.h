#define CPU_BF537    37

#define BOARD_NAME          "SRV-1 Blackfin Camera Board"
#define CPU                 CPU_BF537
#define MASTER_CLOCK        22118000
#define SCLK_DIVIDER        4
#define VCO_MULTIPLIER      22
#define CCLK_DIVIDER        1

#define SDRAM_RECONFIG      1
//#define SDRAM_EBIU_SDRRC    0x03a0

//#define SENSOR_PORT         1  
//#define CONFIG_VIDEO        1

// PLL and clock definitions

// make sure, VCO stays below the nominal operation frequency of the core
// (normally 600 MHz)
//
// VCO = VCO_MULTIPLIER * MASTER_CLOCK / MCLK_DIVIDER
// where MCLK_DIVIDER = 1 when DF bit = 0,  (default)
//                      2               1
// CCLK = VCO / CCLK_DIVIDER
// SCLK = VCO / SCLK_DIVIDER

#define CORE_CLOCK (MASTER_CLOCK * VCO_MULTIPLIER / CCLK_DIVIDER)
#define PERIPHERAL_CLOCK  (CORE_CLOCK / SCLK_DIVIDER)

// UART config
#if defined(__SRV_UART0_BAUDRATE_115200)
	#define UART0_BAUDRATE 115200
#else
	#define UART0_BAUDRATE 2304000
#endif
#define UART1_BAUDRATE 115200

// must be power of 2!
#define FIFO_LENGTH  64
#define FIFO_MODULO_MASK (FIFO_LENGTH - 1)

#define UART0_DIVIDER   (MASTER_CLOCK * VCO_MULTIPLIER / SCLK_DIVIDER \
                        / 16 / UART0_BAUDRATE)
#define UART0_FAST_DIVIDER   (MASTER_CLOCK * VCO_MULTIPLIER / SCLK_DIVIDER \
                        / 16 / UART0_FAST_BAUDRATE)
#define UART_DIVIDER   UART0_DIVIDER
#define UART1_DIVIDER   (MASTER_CLOCK * VCO_MULTIPLIER / SCLK_DIVIDER \
                        / 16 / UART1_BAUDRATE)
// Blackfin environment memory map

#define L1_DATA_SRAM_A 0xff800000
#define FIFOLENGTH 0x100

