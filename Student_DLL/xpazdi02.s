;Login studenta: xpazdi02

[BITS 32]

	;
	GLOBAL DllMain
	EXPORT DllMain

	GLOBAL ipa_algorithm
	EXPORT ipa_algorithm



section .data
	
section .text


DllMain:
	push ebp
	mov ebp,esp
	
	mov esp,ebp
	pop ebp
	mov eax,dword 1
	ret 12


; void ipa_algorithm(
;		unsigned char *input_data, 
;		unsigned char *output_data, 
;		unsigned int width, 
;		unsigned int height, 
;		int argc, char** argv	);	

ipa_algorithm:
	push ebp
	mov ebp,esp
	
	mov esp,ebp
	pop ebp
	ret 0

	
