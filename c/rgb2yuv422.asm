///////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2009  Frank Van Hooft
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details (www.gnu.org/licenses)
//
///////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////////
//
// int read_rgb_yuv (unsigned char * rgb_buff, int N, unsigned short * Y_buff,
//                    unsigned short * CB_buff, unsigned short * CR_buff );
//
// This function implements a portion of the read_rgb24_format() function from the surveyor jpeg.c file
// into Blackfin assembler. Specifically, this portion:
//
// for (j=Y1_cols>>1; j>0; j--)
// {
//	  *CB_Ptr++ = ((128*input_ptr[2] - 85*input_ptr[1] - 43*input_ptr[0] + 128*input_ptr[5] - 85*input_ptr[4] - 43*input_ptr[3])>>9) + 128;
//	  *Y1_Ptr++ = (76*input_ptr[0] + 151*input_ptr[1] + 29*input_ptr[2])>>8;
//	  *CR_Ptr++ = ((128*input_ptr[0] - 107*input_ptr[1] - 21*input_ptr[2] + 128*input_ptr[3] - 107*input_ptr[4] - 21*input_ptr[5])>>9) + 128;
//	  *Y1_Ptr++ = (76*input_ptr[3] + 151*input_ptr[4] + 29*input_ptr[5])>>8;
//	  input_ptr += 6;
// }
//
// There are two of these in the read_rgb24_format() function, and they are very slow. "input_ptr"
// is the rgb_buff. "j" is N. This function is actually performing an RGB to YUV conversion
// using the jpeg equations:
//
//   Y = (76R + 151G + 29B) >>8
//   U = (-43R - 85G + 128B) >>8   + 128     <-- Cb
//   V = (128R - 107G - 21B) >>8   + 128     <-- Cr
//
// where these calculations are performed for pairs of RGB pixels. The Y values are calculated &
// saved for both RGB pixels, however only one U and V value is calculated & saved for the pixel
// pair; it's the average of the U & V values for the two pixels. Think of the two RGB pixels as
// consisting of 6 bytes, labelled (R1, G1, B1), (R2, G2, B2). Then the final equations become:
//
//   Y1 = (76R1 + 151G1 + 29B1) >>8
//   Y2 = (76R2 + 151G2 + 29B2) >>8
//   U = (-43R1 - 85G1 + 128B1 - 43R2 - 85G2 + 128B2) >>9    + 128     <-- Cb
//   V = (128R1 - 107G1 - 21B1 + 128R2 - 107G2 - 21B2) >>9   + 128     <-- Cr
//
// The U & V equations are slightly rearranged, like this:
//   U = (-22R1 -22R2 - 42G1 -  42G2 + 64B1 +64B2) >>8    + 128     <-- Cb
//   V = (64R1 + 64R2 - 54G1 - 54G2 - 10B1 -10B2) >>8     + 128    	<-- Cr
//
// Although the final calculated YUV values are chars (they have the range 0-255), for the jpeg
// encoder they need to be stored as shorts.
//
// As a further refinement, the equations each have 128 subtracted from them, like so:
//   Y1 = (76R1 + 151G1 + 29B1) >>8  - 128
//   Y2 = (76R2 + 151G2 + 29B2) >>8  - 128
//   U = (-22R1 -22R2 - 42G1 -  42G2 + 64B1 +64B2) >>8     <-- Cb
//   V = (64R1 + 64R2 - 54G1 - 54G2 - 10B1 -10B2) >>8      <-- Cr
// Then the "levelshift" function is no longer required in jpeg.c - all it did was subtract 128
// from each of these values. The easiest 16 ms I ever saved!
//
// This function returns N. Be aware that N can be any number, including 1 or zero.
//
// As a slight aside, here are a few YUV colors:
// white: RGB (255, 255, 255)  Y=255, U=128, V=128
// black: RGB (0, 0, 0)        Y=0,   U=128, V=128
// red:   RGB (255, 0, 0)      Y=75,  U=86,  V=255
// green: RGB (0, 255, 0)      Y=150, U=44,  V=22
// blue:  RGB (0, 0, 255)      Y=28,  U=255, V=108


// These are the coefficients for the RGB -> YUV equations. The zero at the 5th element is to
// show that element is not used; it's a filler between the Y coefficients and the U / V coefficients.
// FYI, I suspect that if you need to support BGR input data, all you need to do is change the
// coefficients array around, to this:
// .short 29, 151, 76, 0, 64, -10, -42, -54, -22, 64;
// but I haven't tested that.
.section .l1.data.B,"aw",@progbits
.align 4;
rgbyuv_coeff:
.short 76, 151, 29, 0, -22, 64, -42, -54, 64, -10;


.section        .l1.text,"ax",@progbits
.align 4
.global _read_rgb_yuv;
// .text;

_read_rgb_yuv:
	LINK 0;
    [--SP] = (R7:4, P5:3);          	// Push the registers onto the stack.

	P0 = R0;							// P0 points to the RGB pixel data array
	P1 = R1;							// P1 is "N", the number of rgb pixel-pairs to process, # times to loop

	CC = R1 == 0;						
	IF CC JUMP .read_rgb_yuv_end;		// if N == 0 then exit

	P2 = R2;							// P2 points to Y_buff, where Y calc results are stored

	R0 = [P3+rgbyuv_coeff@GOT17M4];		// get the coefficients array address
	I0 = R0; 							// I0's two LSBs are zero (because array is aligned 4) for BYTEUNPACK later
	I1 = R0;							// I1 points to start of coefficients
	B1 = R0;							// as does B1
	L1 = 20;							// L1 set to 20 bytes to make I1 coefficients pointer be circular

	R0 = [FP+20];
	P3 = R0;							// P3 points to Cb_buff, where the U pixel averages are stored
	R0 = [FP+24];
	P4 = R0;							// P4 points to Cr_buff, where the V pixel averages are stored
	P5 = 2 (Z);							// used to increment address pointer by 2 when reading/writing a 16-bit short
	R7.L = 128;						
	R7.H = 128;							// Used to add 128 to U & V in their calculations


	// First on the agenda is to load up the 6 RGB bytes in as few memory accesses as possible, so we'll do three
	// 16-bit reads. And we want to arrange those 6 bytes so that R1 & R2 are in the same register,
	// G1 & G2 in the same register, and B1 & B2 are in the same register. That'll help the multiplies later on.

	lsetup (.looptop, .loopend) LC0 = P1;		// set up to loop N times 

	R0.L = W[P0++P5];
	R0.H = W[P0++P5];							// R0: R2B1G1R1


.looptop:

	(R3,R2) = BYTEUNPACK R1:0 || R0.L = W[P0++P5]; // R2.L = R1, R2.H = G1, R3.L = B1, R3.H = R2, R0.L = B2G2
	R4 = PACK (R3.H, R2.L);						// R4.H = R2, R4.L = R1
	(R1,R0) = BYTEUNPACK R1:0;					// R0.L = G2, R0.H = B2
	R2 = PACK (R0.L, R2.H) || R5 = [I1++];		// R2.H = G2, R2.L = G1, R5.L = 76, R5.H = 151
	R3 = PACK (R0.H, R3.L) || R0.L = W[P0++P5];	// R3.H = B2, R3.L = B1. R0 starts loading next R2B1G1R1

	// R4 contains R1 & R2, R2 contains G1 & G2, R3 contains B1 & B2, R5 has a couple of coefficients.
	// It's time for a bunch of multiply - accumulates. We calc Y1 & Y2 first.
	A0 = R4.L * R5.L, A1 = R4.H * R5.L (IS) || R6 = [I1++];	  // A0=Y1=76R1, A1=Y2=76R2, R6.L=29, R6.H=0
	A0 += R2.L * R5.H, A1 += R2.H * R5.H (IS) || R5 = [I1++]; // A0=Y1=76R1+151G1, A1=Y2=76R2+151G2, R5.L=-22, R5.H =64
	R1.L = (A0 += R3.L * R6.L), R1.H = (A1 += R3.H * R6.L) (IU) || R6=[I1++]; // R1.L=Y1=76R1+151G1+29B1, R1.H=Y2=76R2+151G2+29B2, R6.L=-42, R6.H=-54

	// Y1 & Y2 have been calc'd, mostly.  Now we start the U & V calcs
	A0 = R4.L * R5.L, A1 = R4.L * R5.H (IS) || R0.H=W[P0++P5];		// A0 = U = -22R1, A1 = V = 64R1, R0=next R2B1G1R1
	R1 = R1 >> 8 (V);												// Y1 & Y2 each get >>8 (unsigned, as always positive)
	R1 = R1 -|- R7;													// Y1 & Y2 each get 128 subtracted from them
	A0 += R4.H * R5.L, A1 += R4.H * R5.H (IS) || R5 = [I1++];		// A0=U += -22R2, A1=V += 64R2, R5.L=64, R5.H=-10
	A0 += R2.L * R6.L, A1 += R2.L * R6.H (IS) || W[P2++P5] = R1.L;	// A0=U += -42G1, A1=V += -54G1, store Y1 result
	A0 += R2.H * R6.L, A1 += R2.H * R6.H (IS) || W[P2++P5] = R1.H;	// A0=U += -42G2, A1=V += -54G2, store Y2 result
	A0 += R3.L * R5.L, A1 += R3.L * R5.H (IS);						// A0=U += 64B1, A1=V += -10B1
	R4.L = (A0 += R3.H * R5.L), R4.H = (A1 += R3.H * R5.H) (IS);	// R4.L=U += 64B2, R4.H=V += -10B2
	R4 = R4 >>> 8 (V);												// U & V each get >>8 (signed, as it can be negative)
	W[P3++P5] = R4.L;												// store U
.loopend:	W[P4++P5] = R4.H;										// store V

.read_rgb_yuv_end:
	R0 = P1;									// return value of N
	L1 = 0;										// all L regs must be zero on exit
	(R7:4,P5:3) = [sp++];						// restore registers from stack
	UNLINK;
	RTS;







//
// putbits_asm
//
// Implements the following from the huffman coder in jpeg.c, into blackfin assembly:
//
//  #define PUTBITS    \
//  {    \
//      bits_in_next_word = (INT16) (bitindex + numbits - 32);    \
//      if (bits_in_next_word < 0)    \
//      {    \
//          lcode = (lcode << numbits) | data;    \
//          bitindex += numbits;    \
//      }    \
//      else    \
//      {    \
//          lcode = (lcode << (32 - bitindex)) | (data >> bits_in_next_word);    \
//          if ((*output_ptr++ = (UINT8)(lcode >> 24)) == 0xff)    \
//              *output_ptr++ = 0;    \
//          if ((*output_ptr++ = (UINT8)(lcode >> 16)) == 0xff)    \
//              *output_ptr++ = 0;    \
//          if ((*output_ptr++ = (UINT8)(lcode >> 8)) == 0xff)    \
//              *output_ptr++ = 0;    \
//          if ((*output_ptr++ = (UINT8) lcode) == 0xff)    \
//              *output_ptr++ = 0;    \
//          lcode = data;    \
//          bitindex = bits_in_next_word;    \
//      }    \
//  }
//
//
//  Prototype is:
//
//  void putbits_asm (int numbits, int data, unsigned char ** output_ptr, 
//				      int * lcode, unsigned short * bitindex );
//
//  output_ptr, lcode and bitindex are all global variables which must be altered by putbits, hence
//  we are passed pointers to them. Note that output_ptr is itself a pointer, so we're passed a pointer
//  to it (ie, a pointer to a pointer). bits_in_next_word is only local within this function.
//
//  In practice I've found that this routine is no faster than what's coded in the jpeg.c file.
//  Calling this function saved zero ms in my jpeg encoding tests. It was an interesting experiment,
//  but not a useful one.
//


.section        .l1.text,"ax",@progbits
.align 4
.global _putbits_asm;
// .text;

_putbits_asm:
	LINK 0;
    [--SP] = (R7:5, P5:4);          			// Push the registers onto the stack.
												// R0 = numbits
												// R1 = data
	P0 = R2;									// P0 = &output_ptr  (ie pointer to the pointer)
	P5 = [FP+24];								// P5 = &bitindex
	P2 = [FP+20];								// P2 = &lcode
	R3 = 32;									// R3 = 32
	P1 = [P0];									// P1 = output_ptr
	R2 = W[P5];									// R2 = bitindex
	R7 = [P2];									// R7 = lcode	

	R5 = R0 - R3;								
	R5 = R5 + R2;								// R5 = bits_in_next_word = bitindex + numbits - 32 
	CC = R5 < 0;
	IF !CC JUMP _putbits_asm_1;

	// Execute here for bits_in_next_word < 0
	R7 <<= R0;									// lcode = lcode << numbits
	R7 = R7 | R1;								// lcode = (lcode << numbits) | data
	R2 = R2 + R0 (NS) || [P2] = R7;				// bitindex += numbits, store lcode
	W[P5] = R2;									// store bitindex
	JUMP _putbits_asm_x;						// it's time to exit

	// Execute here for bits_in_next_word >= 0
_putbits_asm_1:
	R0 = 0;										// R0 = 0  (we no longer need numbits)
	R3 = R3 - R2;								// R3 = (32 - bitindex)
	R6 = R1;
	R6 >>= R5;									// R6 = (data >> bits_in_next_word)
	R7 <<= R3;									// R7 = lcode = (lcode << (32 - bitindex))
	R7 = R7 | R6;								// R7 = lcode = (lcode << (32 - bitindex)) | (data >> bits_in_next_word)
	R3 = 0xFF;									// R3 = 0xFF

	// The following gets a little weird. R7 contains lcode. We process it from high-byte down to low-byte.
	// After we process a highbyte, we want to zero that byte, which we do by shifting it left, ie we 
	// shift the byte left, right out of R7. So effectively, R7 starts off with 32 bits of data, then contains
	// 24 bits, then 16, etc, as we throw away (shift left away) the high bytes.
	R6 = R7 >> 24;								// R6 = high byte of lcode (ie lcode >> 24), lcode byte 3
	R7 = R7 << 8 || B[P1++] = R6;				// *output_ptr++ = (UINT8)(lcode >> 24), R7 = lcode, high byte gone
	CC = R6 == R3;
	IF !CC JUMP _putbits_asm_2;					// IF ((UINT8)(lcode >> 24) == 0xff)
	B[P1++] = R0;								// THEN store *output_ptr++ = 0
_putbits_asm_2:
	R6 = R7 >> 24;								// R6 = lcode byte 2
	R7 = R7 << 8 || B[P1++] = R6;				// *output_ptr++ = (UINT8)(lcode >> 16), R7 = lcode, high word gone
	CC = R6 == R3;
	IF !CC JUMP _putbits_asm_3;					// IF ((UINT8)(lcode >> 16) == 0xff)
	B[P1++] = R0;								// THEN store *output_ptr++ = 0
_putbits_asm_3:
	R6 = R7 >> 24;								// R6 = lcode byte 1
	R7 = R7 << 8 || B[P1++] = R6;				// *output_ptr++ = (UINT8)(lcode >> 8), R7 = lcode, high 24 bits gone
	CC = R6 == R3;
	IF !CC JUMP _putbits_asm_4;					// IF ((UINT8)(lcode >> 8) == 0xff)
	B[P1++] = R0;								// THEN store *output_ptr++ = 0
_putbits_asm_4:
	R7 = R7 >> 24;								// R7 = lcode, low byte (byte 0)
	B[P1++] = R7;								// *output_ptr++ = (UINT8)(lcode >> 8)
	CC = R7 == R3;
	IF !CC JUMP _putbits_asm_5;					// IF ((UINT8)lcode == 0xff)
	B[P1++] = R0;								// THEN store *output_ptr++ = 0
_putbits_asm_5:

	[P2] = R1;									// store  lcode = data
	W[P5] = R5;									// store  bitindex = bits_in_next_word
	[P0] = P1;									// store  updated output_ptr

	// Execute here to exit
_putbits_asm_x:
	(R7:5,P5:4) = [sp++];						// restore registers from stack
	UNLINK;
	RTS;






//
//  quantization_asm
//
//  Implements a blackfin assembler version of the jpeg.c quantization() function.
//
//  void quantization_asm (INT16* data, UINT8* zigzag_table, INT16* Temp, UINT16* quant_table_ptr)
//  {
//      INT16 i;
//      INT32 value;
//
//      for (i=63; i>=0; i--)
//      {
//          value = data [i] * quant_table_ptr [i];
//          value = (value + 0x4000) >> 15;
//
//          Temp [zigzag_table [i]] = (INT16) value;
//      }
//  }
//
//  To make the asm code more efficient, we rearrange the loop so it increments, instead of decrements.
//  Then the actual asm code uses pointers to reference data, quant_table_ptr & zigzag_table
//  rather than indexing. We still need to index for Temp[]. Because zigzag_table does not contain any
//  repeating data (every entry is unique) there's no risk with reversing the loop.
//
//      for (i=0; i<64; i++)
//      {
//          value = data [i] * quant_table_ptr [i];
//          value = (value + 0x4000) >> 15;
//
//          Temp [zigzag_table [i]] = (INT16) value;
//      }
//
//

.section        .l1.text,"ax",@progbits
.align 4
.global _quantization_asm;

_quantization_asm:
	LINK 0;
    [--SP] = (R7:5, P5:5);          			// Push the registers onto the stack.

	P0 = R0;									// P0 = (short*) data pointer
	P2 = R1;									// P2 = (char*) zigzag_table pointer
												// R2 = (INT16*) Temp address
	P5 = 62;									// P5 = 62  (loop this many times)
	P1 = [FP+20];								// P1 = (short*) quant_table_ptr pointer
	R3 = 0x4000 (Z)								// R3 = 0x4000

	// Basically we need to do 3 memory reads (data[i], quant_table_ptr[i], zigzag_table[i]),
	// then a bunch of arithmetic calcs (multiply, add, shift-right), and then one memory write.
	// So we parallel the memory accesses with the arithmetic operations as much as possible
	// within the loop.

	R5 = W[P0++] (X);							// R5 = data[i]
	R1 = W[P1++] (X);							// R1 = quant_table_ptr[i]
	R0 = R5.L * R1.L (IS) ;						// R0 = value (data*quant)
	R0 = R0 + R3 (NS) || R6 = B[P2++] (Z);		// R0 = value = value + 0x4000, R6 = zigzag_table[i]
	R0 = R0 >> 15 || R5 = W[P0++] (X);			// R0 = value = value >> 15, preload next data[i]
	R6 = R6 << 1  || R1 = W[P1++] (X);			// x2 zigzag to make it index, preload next quant[i]
	R7 = R2 + R6;								// R7 is pointer to Temp [zigzag_table [i]]
	I0 = R7;									// I0 points to Temp [zigzag_table [i]]

	lsetup (_quant_looptop, _quant_loopend) LC0 = P5;	// set up to loop 62 times

_quant_looptop:
	R0 = R5.L * R1.L (IS) || W[I0] = R0.L;		// R0 = value (data*quant), store value in Temp [zigzag_table [i]]
	R0 = R0 + R3 (NS) || R6 = B[P2++] (Z);		// R0 = value = value + 0x4000
	R0 = R0 >> 15 || R5 = W[P0++] (X);			// R0 = value = value >> 15, preload next data[i]
	R6 = R6 << 1  || R1 = W[P1++] (X);			// x2 zigzag to make it index, preload next quant[i]
	R7 = R2 + R6;								// R7 is pointer to Temp [zigzag_table [i]]
_quant_loopend:	I0 = R7;						// I0 points to Temp [zigzag_table [i]]

	R0 = R5.L * R1.L (IS) || W[I0] = R0.L;		// R0 = value (data*quant), store value in Temp [zigzag_table [i]]
	R0 = R0 + R3 (NS) || R6 = B[P2++] (Z);		// R0 = value = value + 0x4000, , R6 = zigzag_table[i]
	R0 >>= 15; 									// R0 = value = value >> 15
	R6 <<= 1;									// x2 zigzag to make it a proper index into Temp[]
	R7 = R2 + R6;								// R7 is pointer to Temp [zigzag_table [i]]
	I0 = R7;									// I0 points to Temp [zigzag_table [i]]
	W[I0] = R0.L;								// store value in Temp [zigzag_table [i]]

	(R7:5, P5:5) = [sp++];						// restore registers from stack
	UNLINK;
	RTS;


