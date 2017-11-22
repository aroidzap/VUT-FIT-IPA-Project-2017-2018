;Login studenta: xpazdi02

[BITS 64]

	GLOBAL ipa_algorithm
	EXPORT ipa_algorithm

	GLOBAL transform_image_nearest_avx2_fma
	EXPORT transform_image_nearest_avx2_fma

	EXTERN _ipa_algorithm_c

section .data
section .text

; *** Array Of Structures ***
;
;	char *data == {B,G,R}, {B,G,R}, {B,G,R}, ...
;

; void ipa_algorithm(
;		unsigned char *input_data, 
;		unsigned char *output_data, 
;		unsigned int width, 
;		unsigned int height, 
;		int argc, char** argv	);	

ipa_algorithm:
	jmp _ipa_algorithm_c ;bypass
	push rbp
	mov rbp,rsp
	
	mov rsp,rbp
	pop rbp
	ret 0

	
;// width * height must be divisible by 8
;void transform_image_nearest_avx2_fma(unsigned char *input_data, unsigned char *output_data, mat2x3 matrix, unsigned int width, unsigned int height);

;// Execute: coords[j, i] = vec2( mat2x3 matrix * vec3(i % width, j % height, 1) )
;// +- ??? cycles per 1 vector transformation (average of multiple measurements)

;/*	Execution:
;*	ymm1 = m4, m0, m4, m0, m4, m0, m4, m0
;*	ymm2 = m5, m2, m5, m2, m5, m2, m5, m2
;*	ymm3 = m3, m1, m3, m1, m3, m1, m3, m1
;*	
;*	while(i < count) {
;*		ymm0 = v(3+i), u(3+i), v(2+i), u(2+i), v(1+i), u(1+i), v(0+i), u(0+i);
;*	4X:	coords[i] = vec2( mat2x3 matrix * vec3(vec2 coords[i], 1) );
;*	4X: TODO: popis
;*	}
;*/

transform_image_nearest_avx2_fma:
	push rbp
	mov rbp,rsp

	mov rsi, rcx ;// rsi == input_data
	mov rdi, rdx ;// rdi == output_data
	;// r8 == matrix
	;// r9 == width
	;// [rbp+48] == height	

	;// load matrix to ymm1, ymm2, ymm3
	vbroadcastss ymm0, [r8 + 0 * 4];
	vbroadcastss ymm1, [r8 + 4 * 4];
	vblendps ymm1, ymm0, ymm1, 0xAA;//0b10101010
	vbroadcastss ymm0, [r8 + 2 * 4];
	vbroadcastss ymm2, [r8 + 5 * 4];
	vblendps ymm2, ymm0, ymm2, 0xAA;//0b10101010
	vbroadcastss ymm0, [r8 + 1 * 4];
	vbroadcastss ymm3, [r8 + 3 * 4];
	vblendps ymm3, ymm0, ymm3, 0xAA;//0b10101010

	;// load coordinate count to ecx
	mov eax, [rbp+48];//height
	mov edx, r9d;//width
	mul edx
	mov ecx, eax ;// move width * height to ecx
	and ecx, 0xfffffff8 ;// ensure divisibility by 8

	;// load auxiliary values
	mov eax, r9d;//width
	movd xmm0, eax
	vpbroadcastd ymm0, xmm0 ;//width
	mov eax, -1
	movd xmm5, eax
	vpbroadcastd ymm5, xmm5 ;//-1
	vblendps ymm5, ymm0, ymm5, 0xAA;//0b10101010
	vcvtdq2ps ymm5, ymm5
	;// ymm5 = -1 w -1 w -1 w -1 w

	mov eax, [rbp+48];//height
	movd xmm14, eax
	vpbroadcastd ymm14, xmm14 ;//height
	vblendps ymm14, ymm0, ymm14, 0xAA;//0b10101010
	vcvtdq2ps ymm14, ymm14
	;// ymm14 = h w h w h w h w

	mov eax, 4
	movd xmm0, eax
	vpbroadcastd ymm0, xmm0
	mov eax, 0
	movd xmm6, eax
	vpbroadcastd ymm6, xmm6
	vblendps ymm6, ymm0, ymm6, 0xAA;//0b10101010
	vcvtdq2ps ymm6, ymm6
	;// ymm6 = 0 4 0 4 0 4 0 4

	mov eax, 3
	movd xmm0, eax
	vpbroadcastd ymm0, xmm0 ;//3
	mov edx, 3
	mov eax, r9d;//width
	mul edx
	movd xmm8, eax
	vpbroadcastd ymm8, xmm8 ;//3 * width
	vblendps ymm8, ymm0, ymm8, 0xAA;//0b10101010
	vcvtdq2ps ymm8, ymm8
	;// ymm8 = 3w 3 3w 3 3w 3 3w 3

	vpxor ymm10, ymm10, ymm10
	;// ymm10 = 0 0 0 0 0 0 0 0

	mov eax, -1
	movd xmm12, eax
	vpbroadcastd ymm12, xmm12 
	;// ymm12 = 8x 0xffffffff

	mov rax, 0x0908060504020100
	movq xmm0, rax
	mov rax, 0xffffffff0e0d0c0a
	movq xmm13, rax
	vshufps xmm13, xmm0, xmm13, 0x44;//0b01000100
	vperm2f128 ymm13, ymm13, ymm13, 0
	;// ymm13 = 0xffffffff0e0d0c0a0908060504020100ffffffff0e0d0c0a0908060504020100

	mov eax, 0
	movd xmm0, eax
	vpbroadcastd ymm0, xmm0
	mov eax, 1
	movd xmm4, eax
	vpbroadcastd ymm4, xmm4
	vblendps ymm0, ymm0, ymm4, 0x04;//0b00000100
	mov eax, 2
	movd xmm4, eax
	vpbroadcastd ymm4, xmm4
	vblendps ymm0, ymm0, ymm4, 0x10;//0b00010000
	mov eax, 3
	movd xmm4, eax
	vpbroadcastd ymm4, xmm4
	vblendps ymm0, ymm0, ymm4, 0x40;//0b01000000
	vcvtdq2ps ymm0, ymm0
	;// ymm0 = 0 3 0 2 0 1 0 0
	vsubps ymm0, ymm0, ymm6

l_loop1:
	cmp ecx, 0
	je l_break1

	;// FIRST 4 PIXELS
	;// get x and y position
	vaddps ymm0, ymm0, ymm6
	vcmpgeps ymm7, ymm0, ymm5
	vpermilps ymm7, ymm7, 0xA0;//0b10100000
	vandps ymm4, ymm5, ymm7
	vsubps ymm0, ymm0, ymm4

	;// perform coordinate transformation
	vmovaps ymm4, ymm1
	vfmadd213ps ymm4, ymm0, ymm2
	vpermilps ymm7, ymm0, 0xB1 ;//0b10110001
	vfmadd213ps ymm7, ymm3, ymm4

	;// truncate coordinate
	vroundps ymm7, ymm7, 0 ;//TODO: check rounding mode

	;// check coordinates
	vcmpgeps ymm4, ymm7, ymm14
	vcmpltps ymm9, ymm7, ymm10
	vorps ymm4, ymm4, ymm9
	vpermilps ymm9, ymm4, 0xB1;//0b10110001
	vorps ymm4, ymm4, ymm9

	;// transform coords to index
	vmulps ymm7, ymm7, ymm8
	vpermilps ymm9, ymm7, 0xB1;//0b10110001
	vaddps ymm7, ymm7, ymm9

	vorps ymm7, ymm7, ymm4

	;// ymm7 = UV3id UV3id UV2id UV2id UV1id UV1id UV0id UV0id (id is 0xffffffff if not valid)

	;// ANOTHER 4 PIXELS
	;// get x and y position
	vaddps ymm0, ymm0, ymm6
	vcmpgeps ymm11, ymm0, ymm5
	vpermilps ymm11, ymm11, 0xA0;//0b10100000
	vandps ymm4, ymm5, ymm11
	vsubps ymm0, ymm0, ymm4

	;// perform coordinate transformation
	vmovaps ymm4, ymm1
	vfmadd213ps ymm4, ymm0, ymm2
	vpermilps ymm11, ymm0, 0xB1 ;//0b10110001
	vfmadd213ps ymm11, ymm3, ymm4

	;// truncate coordinate
	vroundps ymm11, ymm11, 0 ;//TODO: check rounding mode

	;// check coordinates
	vcmpgeps ymm4, ymm11, ymm14
	vcmpltps ymm9, ymm11, ymm10
	vorps ymm4, ymm4, ymm9
	vpermilps ymm9, ymm4, 0xB1;//0b10110001
	vorps ymm4, ymm4, ymm9

	;// transform coords to index
	vmulps ymm11, ymm11, ymm8
	vpermilps ymm9, ymm11, 0xB1;//0b10110001
	vaddps ymm11, ymm11, ymm9

	vorps ymm11, ymm11, ymm4

	;// ymm11 = UV7id UV7id UV6id UV6id UV5id UV5id UV4id UV4id (id is 0xffffffff if not valid)


	;// MERGE COORDINATES
	vblendps ymm7, ymm7, ymm11, 0xAA;//0b10101010

	vperm2f128 ymm11, ymm7, ymm7, 1

	vpermilps ymm7, ymm7, 0xD8;//0b11011000
	vpermilps ymm11, ymm11, 0x8D;//0b10001101

	vblendps ymm7, ymm7, ymm11, 0x3C;//0b00111100

	;// ymm7 = UV7id UV6id UV5id UV4id UV3id UV2id UV1id UV0id (id is 0xffffffff if not valid)


	;// read pixels
	vpxor ymm9, ymm9
	vpcmpeqd ymm4, ymm7, ymm12
	vandnps ymm4, ymm4, ymm12
	vcvtps2dq ymm7, ymm7
	vpgatherdd ymm9, [rsi + ymm7], ymm4
	
	;// save pixels
	vpshufb ymm9, ymm9, ymm13
	vperm2f128 ymm7, ymm9, ymm9, 0x11
	vpermilps ymm7, ymm7, 0x39 ;//0b00111001
	vblendps ymm9, ymm9, ymm7, 0x78 ;//0b01111000
	vperm2f128 ymm7, ymm9, ymm9, 0x11

	vmovups [rdi], xmm9
	vmovlps [rdi+16], xmm7

	add rdi, 24

	sub ecx, 8
	jmp l_loop1
l_break1:

	mov rsp,rbp
	pop rbp
	ret 0