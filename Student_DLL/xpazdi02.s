;Login studenta: xpazdi02

[BITS 32]

	;
	GLOBAL DllMain
	EXPORT DllMain

	GLOBAL ipa_algorithm
	EXPORT ipa_algorithm

	EXTERN _ipa_algorithm_c


section .data
	
section .text


DllMain:
	push ebp
	mov ebp,esp
	
	mov esp,ebp
	pop ebp
	mov eax,dword 1
	ret 12


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
	push ebp
	mov ebp,esp
	
	mov esp,ebp
	pop ebp
	ret 0

	
