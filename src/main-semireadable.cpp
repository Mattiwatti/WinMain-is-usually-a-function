// C++ code the assembly version was based on (they are almost the same).

#include "ntdll.h"
#include <ntstatus.h>

using
t_NtRaiseHardError =
NTSTATUS
(NTAPI*)(
	_In_ NTSTATUS ErrorStatus,
	_In_ ULONG NumberOfParameters,
	_In_opt_ ULONG UnicodeStringParameterMask,
	_In_ PULONG_PTR Parameters,
	_In_ HARDERROR_RESPONSE_OPTION ResponseOption,
	_Out_ PHARDERROR_RESPONSE Response
	);

// This routine takes some shortcuts, especially w.r.t forwarded exports which are assumed not to exist.
// There's also no validation of the PE at all. Don't use this for anything
FORCEINLINE
PVOID
GetProcedureAddress(
	_In_ ULONG_PTR DllBase,
	_In_ PCANSI_STRING RoutineName
	)
{
	// Get the PE headers and export directory RVA and size
	PIMAGE_DOS_HEADER DosHeader = reinterpret_cast<PIMAGE_DOS_HEADER>(DllBase);
	PIMAGE_NT_HEADERS NtHeaders = reinterpret_cast<PIMAGE_NT_HEADERS>(DllBase + DosHeader->e_lfanew);
	PIMAGE_DATA_DIRECTORY ImageDirectories;
	if (NtHeaders->OptionalHeader.Magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC)
		ImageDirectories = ((PIMAGE_NT_HEADERS64)NtHeaders)->OptionalHeader.DataDirectory;
	else
		ImageDirectories = ((PIMAGE_NT_HEADERS32)NtHeaders)->OptionalHeader.DataDirectory;
	ULONG ExportDirRva = ImageDirectories[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;

	// Read the export directory
	PIMAGE_EXPORT_DIRECTORY ExportDirectory = reinterpret_cast<PIMAGE_EXPORT_DIRECTORY>(DllBase + ExportDirRva);
	PULONG AddressOfFunctions = reinterpret_cast<PULONG>(DllBase + ExportDirectory->AddressOfFunctions);
	PUSHORT AddressOfNameOrdinals = reinterpret_cast<PUSHORT>(DllBase + ExportDirectory->AddressOfNameOrdinals);
	PULONG AddressOfNames = reinterpret_cast<PULONG>(DllBase + ExportDirectory->AddressOfNames);

	// Iterate over the exports
	for (ULONG i = 0; i < ExportDirectory->NumberOfNames; ++i)
	{
		PCSTR FunctionName = reinterpret_cast<PCSTR>(DllBase + AddressOfNames[i]);
		ULONG FunctionRva = AddressOfFunctions[AddressOfNameOrdinals[i]];
		ULONG j;
		for (j = 0; j < RoutineName->Length; ++j) // Poor man's strcmp
		{
			if (FunctionName[j] != RoutineName->Buffer[j])
				break;
		}
		if (j == RoutineName->Length)
			return reinterpret_cast<PVOID>(DllBase + FunctionRva);
	}
	return nullptr;
}

#pragma code_seg(".text")
__declspec(allocate(".text"))
int WinMainCRTStartup();
__declspec(allocate(".text"))
static constexpr ANSI_STRING RoutineName = RTL_CONSTANT_ANSI_STRING("NtRaiseHardError");
__declspec(allocate(".text"))
static constexpr UNICODE_STRING Message = RTL_CONSTANT_STRING(L"Hello, world!"); // Man I hate this error

int WinMainCRTStartup()
{
	// Get the ntdll base address. Module 0 is our exe and 1 is ntdll, so take the second entry
	PLDR_DATA_TABLE_ENTRY Entry = CONTAINING_RECORD(NtCurrentPeb()->Ldr->InLoadOrderModuleList.Flink->Flink,
													LDR_DATA_TABLE_ENTRY,
													InLoadOrderLinks);

	// Find NtRaiseHardError in the ntdll export table
	t_NtRaiseHardError fpNtRaiseHardError = static_cast<t_NtRaiseHardError>(
		GetProcedureAddress(reinterpret_cast<ULONG_PTR>(Entry->DllBase), &RoutineName));

	// Function parameters
	NTSTATUS ErrorStatus = STATUS_FATAL_APP_EXIT | HARDERROR_OVERRIDE_ERRORMODE;
	ULONG_PTR Parameters[] = { reinterpret_cast<ULONG_PTR>(&Message) };
	HARDERROR_RESPONSE Response;

	return fpNtRaiseHardError(ErrorStatus,	// This status has no predefined error text, which is perfect for us
							1,				// The number of parameters
							1,				// Parameter string mask. (Mask & (1 << ParamIdx)) indicates the parameter is a string
							Parameters,		// The... parameters
							OptionOk,		// One OK button ought to be enough for everyone
							&Response);		// Contains the user response on return. Discarded here, but null isn't allowed
}
