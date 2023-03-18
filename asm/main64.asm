default rel

global WinMainCRTStartup

SECTION .text align=16

align 16
WinMainCRTStartup:
		mov		[rsp+18h], rbx
		push	rbp
		push	rsi
		push	rdi
		push	r12
		push	r14
		sub		rsp, 40h

		mov		rax, [gs:30h]			; Get TEB
		mov		edx, 20Bh
		mov		rcx, [rax+60h]			; Get PEB and traverse to Peb->Ldr->InLoadOrderModuleList.Flink->Flink
		mov		rax, [rcx+18h]
		mov		rcx, [rax+10h]
		mov		rax, [rcx]
		mov		r9, [rax+30h]

		mov		eax, 78h
		movsxd	rcx, dword [r9+3Ch]
		lea		r8d, [rax+10h]
		add		rcx, r9
		cmp		[rcx+18h], dx
		cmovz	eax, r8d
		xor		r10d, r10d
		mov		edi, r10d
		mov		edx, [rax+rcx]
		add		rdx, r9
		mov		r14d, [rdx+1Ch]
		mov		r11d, [rdx+24h]
		add		r14, r9
		mov		ebx, [rdx+20h]
		add		r11, r9
		mov		ebp, [rdx+18h]
		add		rbx, r9
		test	ebp, ebp
		jz		_DoIt
		lea		r12, [aNtRaiseHardError]

_FindExport:
		movzx	eax, word [r11]
		mov		ecx, r10d
		mov		r8d, [rbx]
		mov		rdx, r12
		add		r8, r9
		sub		r8, r12
		mov		esi, [r14+rax*4]

_Strcmp:
		mov		al, [rdx]
		cmp		[r8+rdx], al
		jnz		_EndStrcmp
		inc		ecx
		inc		rdx
		cmp		ecx, 10h
		jb		_Strcmp

_EndStrcmp:
		cmp		ecx, 10h
		jz		_StringMatches
		inc		edi
		add		rbx, 4
		add		r11, 2
		cmp		edi, ebp
		jb		_FindExport
		jmp		_DoIt

_StringMatches:
		lea		r10, [r9+rsi]

_DoIt:
		lea		rax, [uHelloWorld]
		mov		dword [rsp+30h], 1C001Ah	; UNICODE_STRING Length and MaximumLength
		mov		[rsp+38h], rax
		lea		r9, [rsp+78h]				; Parameters
		lea		rax, [rsp+30h]
		mov		edx, 1						; NumberOfParameters
		mov		[rsp+78h], rax

		mov		ecx, 50000015h				; ErrorStatus = STATUS_FATAL_APP_EXIT | HARDERROR_OVERRIDE_ERRORMODE
		lea		rax, [rsp+70h]
		mov		r8d, edx					; UnicodeStringParameterMask
		mov		[rsp+28h], rax				; Response
		mov		dword [rsp+20h], 1			; ResponseOption = OptionOk

		call	r10							; Call NtRaiseHardError

		mov		rbx, [rsp+80h]				; Epilogue
		add		rsp, 40h
		pop		r14
		pop		r12
		pop		rdi
		pop		rsi
		pop		rbp
		ret

; NB: do not use a .data/.rdata section for these strings (no /MERGE:.rdata=.text either, since it will place the strings before the EP)

align 16
aNtRaiseHardError:		db 'NtRaiseHardError',0

%define u(x) __?utf16?__(x)
align 16
uHelloWorld:			dw u(`Hello, world!\0`)
