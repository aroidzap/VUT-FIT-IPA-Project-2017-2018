;/*
;*	Soubor: xpazdi02.s
;*	Projekt: Grafický editor: Rotace obrázku s antialiasingem, VUT FIT 2017/2018
;*	Autor: Tomáš Pazdiora
;*	Login: xpazdi02
;*/

;%define WITHOUT_FMA

[BITS 64]

GLOBAL ipa_algorithm
EXPORT ipa_algorithm

GLOBAL transform_image_nearest_avx2_fma
EXPORT transform_image_nearest_avx2_fma

EXTERN _ipa_algorithm_c

section .data
section .text

; void ipa_algorithm(
;		unsigned char *input_data, 
;		unsigned char *output_data, 
;		unsigned int width, 
;		unsigned int height, 
;		int argc, char** argv	);

;	image data are coded in AOS (Array Of Structures)
;	char *data == {B,G,R}, {B,G,R}, {B,G,R}, ...

ipa_algorithm:
	jmp _ipa_algorithm_c ;bypass, call C function
	push rbp
	mov rbp,rsp
	
	mov rsp,rbp
	pop rbp
	ret 0
	

;void transform_image_nearest_avx2_fma(	unsigned char *input_data, 
;										unsigned char *output_data, mat2x3 matrix, 
;										unsigned int width, 
;										unsigned int height); // requires width >= 4

;/*	Simplified functionality:
;*
;*	while(i < count) {
;*		Generate coords:
;*			CoordsA = GenCoords(); CoordsB = GenCoords();
;*			CoordsA => v3 u3 v2 u2 v1 u1 v0 u0
;*			CoordsB => v7 u7 v6 u6 v5 u5 v4 u4
;*		Transform coords by matrix:
;*			CoordsA = M * CoordsA;
;*			CoordsB = M * CoordsB;
;*		Transform coords to pixel indices:
;*			Indices = GenIndices(CoordsA, CoordsB);
;*			Indices => id7 id6 id5 id4 id3 id2 id1 id0
;*		Transform image with new pixel indices:
;*			Dest[] = Source[Indices];
;*		i += 8;
;*	}
;*
;*/

%macro _vfmadd213ps 3
	%ifndef WITHOUT_FMA
		vfmadd213ps %1, %2, %3
	%else
		vmulps %1, %1, %2
		vaddps %1, %1, %3
	%endif
%endmacro

transform_image_nearest_avx2_fma:
	push rbp
	mov rbp,rsp

	mov rsi, rcx ;// rsi == input_data
	mov rdi, rdx ;// rdi == output_data
	;// r8 == matrix
	;// r9 == width
	;// [rbp+48] == height	

	;// load matrix to ymm1, ymm2, ymm3
	vbroadcastss ymm0, [r8 + 0 * 4]
	vbroadcastss ymm1, [r8 + 4 * 4]
	vblendps ymm1, ymm0, ymm1, 0xAA ;//0b10101010
	vbroadcastss ymm0, [r8 + 2 * 4]
	vbroadcastss ymm2, [r8 + 5 * 4]
	vblendps ymm2, ymm0, ymm2, 0xAA ;//0b10101010
	vbroadcastss ymm0, [r8 + 1 * 4]
	vbroadcastss ymm3, [r8 + 3 * 4]
	vblendps ymm3, ymm0, ymm3, 0xAA ;//0b10101010
	;ymm1 = m4, m0, m4, m0, m4, m0, m4, m0
	;ymm2 = m5, m2, m5, m2, m5, m2, m5, m2
	;ymm3 = m3, m1, m3, m1, m3, m1, m3, m1

	;// load coordinate count to ecx
	mov eax, [rbp+48] ;// height
	mov edx, r9d ;// width
	mul edx
	mov ecx, eax ;// move width * height to ecx

	;// load auxiliary values
	mov eax, r9d ;// width
	movd xmm0, eax
	vpbroadcastd ymm0, xmm0 ;// width
	mov eax, -1
	movd xmm11, eax
	vpbroadcastd ymm11, xmm11 ;// -1
	vblendps ymm5, ymm0, ymm11, 0xAA ;//0b10101010
	vcvtdq2ps ymm5, ymm5
	;// ymm5 = -1 w -1 w -1 w -1 w
	;// ymm11 = 8x 0xffffffff

	mov eax, [rbp+48] ;// height
	movd xmm9, eax
	vpbroadcastd ymm9, xmm9 ;// height
	vblendps ymm9, ymm0, ymm9, 0xAA ;//0b10101010
	vcvtdq2ps ymm9, ymm9
	;// ymm9 = h w h w h w h w

	vpxor ymm10, ymm10, ymm10
	;// ymm10 = 0 0 0 0 0 0 0 0

	mov rax, 0x0908060504020100
	movq xmm0, rax
	mov rax, 0xffffffff0e0d0c0a
	movq xmm12, rax
	vshufps xmm12, xmm0, xmm12, 0x44 ;//0b01000100
	vperm2f128 ymm12, ymm12, ymm12, 0
	;// ymm12 = 0xffffffff0e0d0c0a0908060504020100ffffffff0e0d0c0a0908060504020100

	vaddsubps ymm0, ymm10, ymm5
	vpermilps ymm0, ymm0, 0xB1
	vsubps ymm0, ymm10, ymm0
	vblendps ymm4, ymm10, ymm0, 0x04 ;//0b00000100
	vaddps ymm8, ymm0, ymm0
	vblendps ymm4, ymm4, ymm8, 0x10 ;//0b00010000
	vaddps ymm8, ymm8, ymm0
	vblendps ymm4, ymm4, ymm8, 0x40 ;//0b01000000
	vaddps ymm0, ymm8, ymm0
	vblendps ymm6, ymm0, ymm10, 0xAA ;//0b10101010
	vsubps ymm0, ymm4, ymm6
	;// ymm8 = 3w 3 3w 3 3w 3 3w 3
	;// ymm6 = 0 4 0 4 0 4 0 4
	;// ymm0 = 0 -1 0 -2 0 -3 0 -4


	;// ------------ REGISTER VALUES ------------

	;// *ymm0 = 0 3 0 2 0 1 0 0 - (0 4 0 4 0 4 0 4)	
	;// ymm1 = m4, m0, m4, m0, m4, m0, m4, m0
	;// ymm2 = m5, m2, m5, m2, m5, m2, m5, m2
	;// ymm3 = m3, m1, m3, m1, m3, m1, m3, m1
	;// *ymm4 = TEMP
	;// ymm5 = -1 w -1 w -1 w -1 w
	;// ymm6 = 0 4 0 4 0 4 0 4
	;// *ymm7 = TEMP
	;// ymm8 = 3w 3 3w 3 3w 3 3w 3
	;// ymm9 = h w h w h w h w
	;// ymm10 = 0 0 0 0 0 0 0 0
	;// ymm11 = 8x 0xffffffff
	;// ymm12 = 0xffffffff0e0d0c0a0908060504020100ffffffff0e0d0c0a0908060504020100
	;// *ymm13 = TEMP
	;// *ymm14 = TEMP

	;// registers with asterisk * are not constant within the loop

_loop:
	cmp ecx, 0
	jle _break

	;// FIRST 4 PIXELS
	;// get x and y position
	vaddps ymm0, ymm0, ymm6
	vcmpgeps ymm7, ymm0, ymm5
	vpermilps ymm7, ymm7, 0xA0 ;//0b10100000
	vandps ymm4, ymm5, ymm7
	vsubps ymm0, ymm0, ymm4

	;// perform coordinate transformation (u,v) = M * (u,v)
	vmovaps ymm4, ymm1
	_vfmadd213ps ymm4, ymm0, ymm2
	vpermilps ymm7, ymm0, 0xB1 ;//0b10110001
	_vfmadd213ps ymm7, ymm3, ymm4

	;// truncate coordinate
	vroundps ymm7, ymm7, 0x0B ;//Round toward zero (truncate), Do not signal precision exception on SNaN

	;// check coordinates (u,v) in ( <0, width-1>, <0, height-1> )
	vcmpgeps ymm4, ymm7, ymm9
	vcmpltps ymm13, ymm7, ymm10
	vorps ymm4, ymm4, ymm13
	vpermilps ymm13, ymm4, 0xB1 ;//0b10110001
	vorps ymm4, ymm4, ymm13

	;// transform coords to pixel index (u,v) -> 3(v*width + v)
	vmulps ymm7, ymm7, ymm8
	vpermilps ymm13, ymm7, 0xB1 ;//0b10110001
	vaddps ymm7, ymm7, ymm13

	vorps ymm7, ymm7, ymm4

	;// ymm7 = UV3id UV3id UV2id UV2id UV1id UV1id UV0id UV0id (id is 0xffffffff if not valid)

	;// ANOTHER 4 PIXELS
	;// get x and y position
	vaddps ymm0, ymm0, ymm6
	vcmpgeps ymm14, ymm0, ymm5
	vpermilps ymm14, ymm14, 0xA0 ;//0b10100000
	vandps ymm4, ymm5, ymm14
	vsubps ymm0, ymm0, ymm4

	;// perform coordinate transformation (u,v) = M * (u,v)
	vmovaps ymm4, ymm1
	_vfmadd213ps ymm4, ymm0, ymm2
	vpermilps ymm14, ymm0, 0xB1 ;//0b10110001
	_vfmadd213ps ymm14, ymm3, ymm4

	;// truncate coordinate
	vroundps ymm14, ymm14, 0x0B ;//Round toward zero (truncate), Do not signal precision exception on SNaN

	;// check coordinates (u,v) in ( <0, width-1>, <0, height-1> )
	vcmpgeps ymm4, ymm14, ymm9
	vcmpltps ymm13, ymm14, ymm10
	vorps ymm4, ymm4, ymm13
	vpermilps ymm13, ymm4, 0xB1 ;//0b10110001
	vorps ymm4, ymm4, ymm13

	;// transform coords to pixel index (u,v) -> 3(v*width + v)
	vmulps ymm14, ymm14, ymm8
	vpermilps ymm13, ymm14, 0xB1 ;//0b10110001
	vaddps ymm14, ymm14, ymm13

	vorps ymm14, ymm14, ymm4

	;// ymm14 = UV7id UV7id UV6id UV6id UV5id UV5id UV4id UV4id (id is 0xffffffff if not valid)


	;// MERGE COORDINATES
	vblendps ymm7, ymm7, ymm14, 0xAA ;//0b10101010
	vperm2f128 ymm14, ymm7, ymm7, 1
	vpermilps ymm7, ymm7, 0xD8 ;//0b11011000
	vpermilps ymm14, ymm14, 0x8D ;//0b10001101
	vblendps ymm7, ymm7, ymm14, 0x3C ;//0b00111100
	;// ymm7 = UV7id UV6id UV5id UV4id UV3id UV2id UV1id UV0id (id is 0xffffffff if not valid)


	;// read pixels
	vpxor ymm13, ymm13
	vandnps ymm4, ymm7, ymm11 ;// extract id mask
	vcvtps2dq ymm7, ymm7
	vpgatherdd ymm13, [rsi + ymm7], ymm4
	;//ymm13 -> XXR7G7B7 XXR6G6B6 XXR5G5B5 XXR4G4B4 XXR3G3B3 XXR2G2B2 XXR1G1B1 XXR0G0B0

	;// save pixels
	vpshufb ymm13, ymm13, ymm12
	vperm2f128 ymm7, ymm13, ymm13, 0x11
	vpermilps ymm7, ymm7, 0x39 ;//0b00111001
	vblendps ymm13, ymm13, ymm7, 0x78 ;//0b01111000
	vperm2f128 ymm7, ymm13, ymm13, 0x11
	;//xmm13 -> B5R4G4B4 R3G3B3R2 G2B2R1G1 B1R0G0B0
	;//xmm7  -> XXXXXXXX XXXXXXXX R7G7B7R6 G6B6R5G5

	;// check for remaining count < 8
	cmp ecx, 8
	jl _non_divisible_pixel_cnt

	;// save pixels to memory
	vmovups [rdi], xmm13
	vmovlps [rdi+16], xmm7
	add rdi, 24

	sub ecx, 8
	jmp _loop


_non_divisible_pixel_cnt: 
	;//save last few pixels, which count is not divisible by 8
	and rsp, 0xfffffffffffffff0
	mov rdx, rsp
	sub rdx, 32
	vmovaps [rdx], xmm13
	vmovaps [rdx+16], xmm7
	
	;// save remaining pixels to memory
__loop_save_remaining:
	mov ax, [rdx]
	mov [rdi], ax
	mov al, [rdx+2]
	mov [rdi+2], al
	add rdi, 3
	add rdx, 3
	dec ecx
	cmp ecx, 0
	jg __loop_save_remaining

_break:
	mov rsp,rbp
	pop rbp
	ret 0