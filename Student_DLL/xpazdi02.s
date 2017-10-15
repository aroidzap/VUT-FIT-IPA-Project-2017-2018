;Login studenta:

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
		
ipa_algorithm:
	push ebp
	mov ebp,esp
	
	mov esp,ebp
	pop ebp
	ret 0

	
