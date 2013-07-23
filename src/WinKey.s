; Copyright 2001-2013, Stephen Fryatt (info@stevefryatt.org.uk)
;
; This file is part of WinKeys:
;
;   http://www.stevefryatt.org.uk/software/
;
; Licensed under the EUPL, Version 1.1 only (the "Licence");
; You may not use this work except in compliance with the
; Licence.
;
; You may obtain a copy of the Licence at:
;
;   http://joinup.ec.europa.eu/software/page/eupl
;
; Unless required by applicable law or agreed to in
; writing, software distributed under the Licence is
; distributed on an "AS IS" basis, WITHOUT WARRANTIES
; OR CONDITIONS OF ANY KIND, either express or implied.
;
; See the Licence for the specific language governing
; permissions and limitations under the Licence.

; WinKey.s
;
; WinKeys Module Source
;
; REM 26/32 bit neutral

;version$="0.21"
;save_as$="WinKeys"

	GET	$Include/SWINames

; ---------------------------------------------------------------------------------------------------------------------
; Set up the Module Workspace

WS_BlockSize		*	256
WS_TargetSize		*	&500

			^	0
WS_TaskHandle		#	4
WS_Quit			#	4
WS_WinHandle		#	4
WS_Block		#	WS_BlockSize
WS_Stack		#	WS_TargetSize - @

WS_Size			*	@


; ======================================================================================================================
; Module Header

	AREA	Module,CODE,READONLY
	ENTRY

ModuleHeader
	DCD	TaskCode			; Offset to task code
	DCD	InitCode			; Offset to initialisation code
	DCD	FinalCode			; Offset to finalisation code
	DCD	ServiceCode			; Offset to service-call handler
	DCD	TitleString			; Offset to title string
	DCD	HelpString			; Offset to help string
	DCD	CommandTable			; Offset to command table
	DCD	0				; SWI Chunk number
	DCD	0				; Offset to SWI handler code
	DCD	0				; Offset to SWI decoding table
	DCD	0				; Offset to SWI decoding code
	DCD	0				; MessageTrans file
	DCD	ModuleFlags			; Offset to module flags

; ======================================================================================================================

ModuleFlags
	DCD	1				; 32-bit compatible

; ======================================================================================================================

TitleString
	DCB	"WindowsKeys",0
	ALIGN

HelpString
	DCB	"Windows Keys",9,$BuildVersion," (",$BuildDate,") ",169," Stephen Fryatt, 2001",0 ;-",$BuildDate:RIGHT:4,0
	ALIGN

; ======================================================================================================================

CommandTable
	DCB	"Desktop_WindowsKeys",0
	ALIGN
	DCD	CommandDesktop
	DCD	&00000000
	DCD	0
	DCD	0

	DCD	0

; ----------------------------------------------------------------------------------------------------------------------

CommandDesktop
	STMFD	R13!,{R14}

	MOV	R2,R0
	ADR	R1,title_string
	MOV	R0,#2
	SWI	XOS_Module

	LDMFD	R13!,{PC}

; ======================================================================================================================

InitCode
          STMFD     R13!,{R14}

; Claim 296 bytes of workspace for ourselves and store the pointer in our private workspace.
; This space is used for everything; both the module 'back-end' and the WIMP task.

          MOV       R0,#6
          MOV       R3,#WS_Size
          SWI       "XOS_Module"
          BVS       init_exit
          STR       R2,[R12]
          MOV       R12,R2

; Initialise the workspace that was just claimed.

          MOV       R0,#0
          STR       R0,[R12,#WS_TaskHandle]         ; Zero the task handle.

.init_exit
          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

FinalCode
          STMFD     R13!,{R14}
          LDR       R12,[R12]

; Kill the wimp task if it's running.

          LDR       R0,[R12,#WS_TaskHandle]
          CMP       R0,#0
          BLE       final_free_ws

          LDR       R1,Task
          SWI       "XWimp_CloseDown"
          MOV       R1,#0
          STR       R1,[R12,#WS_TaskHandle]

.final_free_ws
          TEQ       R10,#1
          TEQEQ     R12,#0
          BEQ       final_exit
          MOV       R0,#7
          MOV       R2,R12
          SWI       "XOS_Module"

.final_exit
          LDMFD     R13!,{PC}

; ======================================================================================================================

ServiceCode
          TEQ       R1,#&27
          TEQNE     R1,#&49
          TEQNE     R1,#&4A

          MOVNE     PC,R14

          STMFD     R13!,{R14}
          LDR       R12,[R12]

.service_reset
          TEQ       R1,#&27
          BNE       service_start_wimp

          MOV       R14,#0
          STR       R14,[R12,#WS_TaskHandle]
          LDMFD     R13!,{PC}

.service_start_wimp
          TEQ       R1,#46
          BNE       service_started_wimp

          LDR       R14,[R12,#WS_TaskHandle]
          TEQ       R14,#0
          MOVEQ     R14,#NOT-1
          STREQ     R14,[R12,#WS_TaskHandle]
          ADREQ     R0,CommandDesktop
          MOVEQ     R1,#0
          LDMFD     R13!,{PC}

.service_started_wimp
          LDR       R14,[R12,#WS_TaskHandle]
          CMN       R14,#1
          MOVEQ     R14,#0
          STREQ     R14,[R12,#WS_TaskHandle]
          LDMFD     R13!,{PC}

; ======================================================================================================================

Task
	DCB	"TASK"

WimpVersion
	DCD	310

WimpMessageList
	DCD	0

PollMask
	DCD	&3831

TaskName
	DCB	"Windows Keys",0

MisusedStartCommand
	DCD	0
	DCB	"Use *Desktop to start WinKeys.",0
	ALIGN

WindowDefinition
	DCD	-400		; Visible area min x
	DCD	-400		; Visible area min y
	DCD	-100		; Visible area max x
	DCD	-100		; Visible area max y
	DCD	0		; X scroll offset
	DCD	0		; Y scroll offset
	DCD	-3		; Handle to open window behind
	DCD	&84001050	; Window flags
	DCD	&07020701
	DCD	&07020C00
	DCD	0		; Work area min x
	DCD	-300		; Work area min y
	DCD	300		; Work area max x
	DCD	0		; Work area max y
	DCD	&19		; Title bar icon flags
	DCD	0		; Work area flags
	DCD	1		; Sprite area pointer
	DCW	0		; Minimum width of window
	DCW	0		; Minimum height of window
	DCB	"Win Key Grab"
	DCD	0		; Number of icons
	ALIGN

; ======================================================================================================================

TaskCode
          LDR       R12,[R12]
          ADRW      R13,WS_Size+4         ; Set the stack up.

; Check that we aren't in the desktop.

          SWI       "XWimp_ReadSysInfo"
          TEQ       R0,#0
          ADREQ     R0,MisusedStartCommand
          SWIEQ     "OS_GenerateError"

; Kill any previous version of our task which may be running.

          LDR       R0,[R12,#WS_TaskHandle]
          TEQ       R0,#0
          LDRGT     R1,Task
          SWIGT     "XWimp_CloseDown"
          MOV       R0,#0
          STRGT     R0,[R12,#WS_TaskHandle]

; Set the Quit flag to zero

          STR       R0,[R12,#WS_Quit]

; (Re) initialise the module as a Wimp task.

          LDR       R0,WimpVersion
          LDR       R1,Task
          ADR       R2,TaskName
          ADR       R3,WimpMessageList
          SWI       "XWimp_Initialise"
          SWIVS     "OS_Exit"
          STR       R1,[R12,#WS_TaskHandle]

; Create the window and open it on the next poll.

          ADR       R1,WindowDefinition
          SWI       "Wimp_CreateWindow"
          STR       R0,[R12,#WS_WinHandle]

          ADRW      R1,WS_Block

          STR       R0,[R1,#0]
          SWI       "Wimp_GetWindowState"
          MVN       R0,#NOT-3
          STR       R0,[R1,#24]
          SWI       "Wimp_OpenWindow"

; Set the variables from the choices file (an obey file).

          BL        SetKeyVariables

; ----------------------------------------------------------------------------------------------------------------------

.poll_loop
          LDR       R0,PollMask
          SWI       "Wimp_Poll"

.poll_event_open_window
          TEQ       R0,#2
          BNE       poll_event_close_window

          SWI       "Wimp_OpenWindow"
          B         poll_loop_end

.poll_event_close_window
          TEQ       R0,#3
          BNE       poll_event_key_press

          SWI       "Wimp_CloseWindow"
          B         poll_loop_end

.poll_event_key_press
          TEQ       R0,#8
          BNE       poll_event_wimp_message

          BL        key_press
          B         poll_loop_end

.poll_event_wimp_message
          TEQ       R0,#17
          TEQNE     R0,#18
          BNE       poll_loop_end

          LDR       R0,[R1,#16]
          TEQ       R0,#0
          MOVEQ     R0,#1
          STREQ     R0,[R12,#WS_Quit]

.poll_loop_end
          LDR       R0,[R12,#WS_Quit]
          TEQ       R0,#0
          BEQ       poll_loop

; ----------------------------------------------------------------------------------------------------------------------

.close_down
          LDR       R0,[R12,#WS_TaskHandle]
          LDR       R1,Task
          SWI       "XWimp_CloseDown"

; Set the task handle to zero and die.

          MOV       R0,#0
          STR       R0,[R12,#WS_TaskHandle]

          SWI       "OS_Exit"

; ======================================================================================================================

Key1
	DCB	"WinKeys$Win",0
Key2
	DCB	"WinKeys$ShiftWin",0
Key3
	DCB	"WinKeys$CtrlWin",0
Key4
	DCB	"WinKeys$ShiftCtrlWin",0
Key5
	DCB	"WinKeys$Menu",0
Key6
	DCB	"WinKeys$ShiftMenu",0
Key7
	DCB	"WinKeys$CtrlMenu",0
Key8
	DCB	"WinKeys$ShiftCtrlMenu",0
	ALIGN

; ----------------------------------------------------------------------------------------------------------------------

.key_press
          STMFD     R13!,{R14}

          LDR       R5,[R1,#24]

          MOV       R2,#&1C0
          TEQ       R5,R2
          ADREQ     R0,Key1
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,Key5
          BEQ       key_press_found

          MOV       R2,#&1D0
          TEQ       R5,R2
          ADREQ     R0,Key2
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,Key6
          BEQ       key_press_found

          MOV       R2,#&1E0
          TEQ       R5,R2
          ADREQ     R0,Key3
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,Key7
          BEQ       key_press_found

          MOV       R2,#&1F0
          TEQ       R5,R2
          ADREQ     R0,Key4
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,Key8
          BEQ       key_press_found

          MOV       R0,R5
          SWI       "Wimp_ProcessKey"
          LDMFD     R13!,{PC}

.key_press_found
          MOV       R2,#256
          MOV       R3,#0
          MOV       R4,#0
          SWI       "XOS_ReadVarVal"

          MOV       R0,#0
          STRB      R0,[R1,R2]
          MOV       R0,R1

          TEQ       R2,#0
          BNE       key_press_run_command

          MOV       R5,R0
          SWI       "Wimp_ProcessKey"
          LDMFD     R13!,{PC}

.key_press_run_command
          SWINE     "XWimp_StartTask"
          LDMFD     R13!,{PC}

; ======================================================================================================================

.key_file_run
          DCB      "Filer_Run "

.key_file
          DCB      "Choices:WinKeys.SetKeys",0
          ALIGN

; ----------------------------------------------------------------------------------------------------------------------

SetKeyVariables
	STMFD	R13!,{R0-R6,R14}

	MOV	R0,#23
	ADR	R1,key_file
	SWI	XOS_File
	LDMVSFD	R13!,{R0-R6,PC}

	TEQ	R0,#1
	LDMNEFD	R13!,{R0-R6,PC}

	ADR	R0,key_file_run
	SWI	XOS_CLI

	LDMFD	R13!,{R0-R6,PC}

	END

