global WinMainCRTStartup

SECTION .text align=16

align 16
WinMainCRTStartup:
		sub		esp, 20h
		mov		eax, [fs:18h]				; Get TEB

		push	ebx
		push	ebp
		push	esi
		mov		eax, [eax+30h]				; Get PEB and traverse to Peb->Ldr->InLoadOrderModuleList.Flink->Flink
		mov		esi, 20Bh
		push	edi
		push	78h
		mov		eax, [eax+0Ch]
		mov		eax, [eax+0Ch]
		mov		eax, [eax]
		mov		edi, [eax+18h]
		pop		eax
		mov		ecx, [edi+3Ch]
		add		ecx, edi
		lea		edx, [eax+10h]
		cmp		[ecx+18h], si
		cmovz	eax, edx
		xor		ebx, ebx
		mov		edx, ebx
		mov		eax, [eax+ecx]
		add		eax, edi
		mov		ecx, [eax+1Ch]
		mov		ebp, [eax+24h]
		add		ecx, edi
		mov		esi, [eax+20h]
		add		ebp, edi
		mov		eax, [eax+18h]
		add		esi, edi
		mov		[esp+14h], ecx
		mov		[esp+18h], ebp
		mov		[esp+1Ch], esi
		mov		[esp+10h], eax
		test	eax, eax
		jz		_DoIt

_FindExport:
		movzx	eax, word [ebp+edx*2+0]
		mov		esi, [esi+edx*4]
		add		esi, edi
		sub		esi, aNtRaiseHardError
		mov		ebp, [ecx+eax*4]
		mov		ecx, ebx

_Strcmp:
		mov		al, byte [aNtRaiseHardError+esi+ecx]
		cmp		al, byte [aNtRaiseHardError+ecx]
		jnz		_EndStrcmp
		inc		ecx
		cmp		ecx, 10h
		jb		_Strcmp

_EndStrcmp:
		cmp		ecx, 10h
		jz		_StringMatches
		mov		ecx, [esp+14h]
		inc		edx
		mov		ebp, [esp+18h]
		mov		esi, [esp+1Ch]
		cmp		edx, [esp+10h]
		jb		_FindExport
		jmp		_DoIt

_StringMatches:
		lea		ebx, [edi+ebp]

_DoIt:
		push	1Ah							; UNICODE_STRING Length
		pop		eax
		push	1Ch							; UNICODE_STRING MaximumLength
		mov		[esp+2Ch], ax
		pop		eax
		mov		[esp+2Ah], ax
		lea		eax, [esp+28h]
		mov		[esp+20h], eax
		lea		eax, [esp+24h]
		push	eax							; Response
		push	1							; ResponseOption = OptionOk
		lea		eax, [esp+28h]
		mov		dword [esp+34h], uHelloWorld
		push	eax							; Parameters
		push	1							; UnicodeStringParameterMask
		push	1							; NumberOfParameters
		push	50000015h					; ErrorStatus = STATUS_FATAL_APP_EXIT | HARDERROR_OVERRIDE_ERRORMODE

		call	ebx							; Call NtRaiseHardError

		pop		edi							; Epilogue
		pop		esi
		pop		ebp
		pop		ebx
		add		esp, 20h
		ret

; NB: do not use a .data/.rdata section for these strings (no /MERGE:.rdata=.text either, since it will place the strings before the EP)

align 16
aNtRaiseHardError:		db 'NtRaiseHardError',0

%define u(x) __?utf16?__(x)
align 16
uHelloWorld:			dw u(`Hello, world!\0`)
