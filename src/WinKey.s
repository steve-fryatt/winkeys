REM >WinKeySrc
REM WinKeys Module
REM
REM Do something with the extra keys on the keyboard.
REM
REM (c) Stephen Fryatt, 2001
REM
REM Needs ExtBasAsm to assemble.
REM 26/32 bit neutral

version$="0.21"
save_as$="WinKeys"

LIBRARY "<Reporter$Dir>.AsmLib"

PRINT "Assemble debug? (Y/N)"
REPEAT
 g%=GET
UNTIL (g% AND &DF)=ASC("Y") OR (g% AND &DF)=ASC("N")
debug%=((g% AND &DF)=ASC("Y"))

ON ERROR PRINT REPORT$;" at line ";ERL : END

REM --------------------------------------------------------------------------------------------------------------------
REM Set up workspace

workspace_size%=0 : REM This is updated.

task_handle%=FNworkspace(workspace_size%,4)
quit%=FNworkspace(workspace_size%,4)
win_handle%=FNworkspace(workspace_size%,4)
block%=FNworkspace(workspace_size%,256)

stack%=FNworkspace(workspace_size%,1012)

REM --------------------------------------------------------------------------------------------------------------------

DIM time% 5, date% 256
?time%=3
SYS "OS_Word",14,time%
SYS "Territory_ConvertDateAndTime",-1,time%,date%,255,"(%dy %m3 %ce%yr)" TO ,date_end%
?date_end%=13

REM --------------------------------------------------------------------------------------------------------------------

code_space%=4000
DIM code% code_space%

IF debug% THEN PROCReportInit(200)


FOR pass%=%11100 TO %11110 STEP 2
L%=code%+code_space%
O%=code%
P%=0
IF debug% THEN PROCReportStart(pass%)
[OPT pass%
EXT 1
          EQUD      task_code           ; Offset to task code
          EQUD      init_code           ; Offset to initialisation code
          EQUD      final_code          ; Offset to finalisation code
          EQUD      service_code        ; Offset to service-call handler
          EQUD      title_string        ; Offset to title string
          EQUD      help_string         ; Offset to help string
          EQUD      command_table       ; Offset to command table
          EQUD      0                   ; SWI Chunk number
          EQUD      0                   ; Offset to SWI handler code
          EQUD      0                   ; Offset to SWI decoding table
          EQUD      0                   ; Offset to SWI decoding code
          EQUD      0                   ; MessageTrans file
          EQUD      module_flags

; ======================================================================================================================

.module_flags
          EQUD      1                   ; 32-bit compatible

; ======================================================================================================================

.title_string
          EQUZ      "WindowsKeys"
          ALIGN

.help_string
          EQUS      "Windows Keys"
          EQUB      9
          EQUS      version$
          EQUS      " "
          EQUS      $date%
          EQUZ      " © Stephen Fryatt, 2001"
          ALIGN

; ======================================================================================================================

.command_table
          EQUZ      "Desktop_WindowsKeys"
          ALIGN
          EQUD      command_desktop
          EQUD      &00000000
          EQUD      0
          EQUD      0

          EQUD      0

; ----------------------------------------------------------------------------------------------------------------------

.command_desktop
          STMFD     R13!,{R14}

          MOV       R2,R0
          ADR       R1,title_string
          MOV       R0,#2
          SWI       "XOS_Module"

          LDMFD     R13!,{PC}

; ======================================================================================================================
.init_code
          STMFD     R13!,{R14}

; Claim 296 bytes of workspace for ourselves and store the pointer in our private workspace.
; This space is used for everything; both the module 'back-end' and the WIMP task.

          MOV       R0,#6
          MOV       R3,#workspace_size%
          SWI       "XOS_Module"
          BVS       init_exit
          STR       R2,[R12]
          MOV       R12,R2

; Initialise the workspace that was just claimed.

          MOV       R0,#0
          STR       R0,[R12,#task_handle%]         ; Zero the task handle.

.init_exit
          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------
.final_code
          STMFD     R13!,{R14}
          LDR       R12,[R12]

; Kill the wimp task if it's running.

          LDR       R0,[R12,#task_handle%]
          CMP       R0,#0
          BLE       final_free_ws

          LDR       R1,task
          SWI       "XWimp_CloseDown"
          MOV       R1,#0
          STR       R1,[R12,#task_handle%]

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

.service_code
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
          STR       R14,[R12,#task_handle%]
          LDMFD     R13!,{PC}

.service_start_wimp
          TEQ       R1,#46
          BNE       service_started_wimp

          LDR       R14,[R12,#task_handle%]
          TEQ       R14,#0
          MOVEQ     R14,#NOT-1
          STREQ     R14,[R12,#task_handle%]
          ADREQ     R0,command_desktop
          MOVEQ     R1,#0
          LDMFD     R13!,{PC}

.service_started_wimp
          LDR       R14,[R12,#task_handle%]
          CMN       R14,#1
          MOVEQ     R14,#0
          STREQ     R14,[R12,#task_handle%]
          LDMFD     R13!,{PC}

; ======================================================================================================================

.task
          EQUS      "TASK"

.wimp_version
          EQUD      310

.wimp_messages
          EQUD      0

.poll_mask
          EQUD      &3831

.task_name
          EQUZ      "Windows Keys"

.misused_start_command
          EQUD      0
          EQUZ      "Use *Desktop to start WinKeys."
          ALIGN

.window_definition
          EQUD      -400      ; Visible area min x
          EQUD      -400      ; Visible area min y
          EQUD      -100      ; Visible area max x
          EQUD      -100      ; Visible area max y
          EQUD      0         ; X scroll offset
          EQUD      0         ; Y scroll offset
          EQUD      -3        ; Handle to open window behind
          EQUD      &84001050 ; Window flags
          EQUD      &07020701
          EQUD      &07020C00
          EQUD      0         ; Work area min x
          EQUD      -300      ; Work area min y
          EQUD      300       ; Work area max x
          EQUD      0         ; Work area max y
          EQUD      &19       ; Title bar icon flags
          EQUD      0         ; Work area flags
          EQUD      1         ; Sprite area pointer
          EQUW      0         ; Minimum width of window
          EQUW      0         ; Minimum height of window
          EQUS      "Win Key Grab"
          EQUD      0         ; Number of icons
          ALIGN

; ======================================================================================================================

.task_code
          LDR       R12,[R12]
          ADRW      R13,workspace_size%+4         ; Set the stack up.

; Check that we aren't in the desktop.

          SWI       "XWimp_ReadSysInfo"
          TEQ       R0,#0
          ADREQ     R0,misused_start_command
          SWIEQ     "OS_GenerateError"

; Kill any previous version of our task which may be running.

          LDR       R0,[R12,#task_handle%]
          TEQ       R0,#0
          LDRGT     R1,task
          SWIGT     "XWimp_CloseDown"
          MOV       R0,#0
          STRGT     R0,[R12,#task_handle%]

; Set the Quit flag to zero

          STR       R0,[R12,#quit%]

; (Re) initialise the module as a Wimp task.

          LDR       R0,wimp_version
          LDR       R1,task
          ADR       R2,task_name
          ADR       R3,wimp_messages
          SWI       "XWimp_Initialise"
          SWIVS     "OS_Exit"
          STR       R1,[R12,#task_handle%]

; Create the window and open it on the next poll.

          ADR       R1,window_definition
          SWI       "Wimp_CreateWindow"
          STR       R0,[R12,#win_handle%]

          ADRW      R1,block%

          STR       R0,[R1,#0]
          SWI       "Wimp_GetWindowState"
          MVN       R0,#NOT-3
          STR       R0,[R1,#24]
          SWI       "Wimp_OpenWindow"

; Set the variables from the choices file (an obey file).

          BL        set_key_vars

; ----------------------------------------------------------------------------------------------------------------------

.poll_loop
          LDR       R0,poll_mask
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
          STREQ     R0,[R12,#quit%]

.poll_loop_end
          LDR       R0,[R12,#quit%]
          TEQ       R0,#0
          BEQ       poll_loop

; ----------------------------------------------------------------------------------------------------------------------

.close_down
          LDR       R0,[R12,#task_handle%]
          LDR       R1,task
          SWI       "XWimp_CloseDown"

; Set the task handle to zero and die.

          MOV       R0,#0
          STR       R0,[R12,#task_handle%]

          SWI       "OS_Exit"

; ======================================================================================================================

.key_1
          EQUZ      "WinKeys$Win"
.key_2
          EQUZ      "WinKeys$ShiftWin"
.key_3
          EQUZ      "WinKeys$CtrlWin"
.key_4
          EQUZ      "WinKeys$ShiftCtrlWin"
.key_5
          EQUZ      "WinKeys$Menu"
.key_6
          EQUZ      "WinKeys$ShiftMenu"
.key_7
          EQUZ      "WinKeys$CtrlMenu"
.key_8
          EQUZ      "WinKeys$ShiftCtrlMenu"
          ALIGN

; ----------------------------------------------------------------------------------------------------------------------

.key_press
          STMFD     R13!,{R14}

          LDR       R5,[R1,#24]

          MOV       R2,#&1C0
          TEQ       R5,R2
          ADREQ     R0,key_1
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,key_5
          BEQ       key_press_found

          MOV       R2,#&1D0
          TEQ       R5,R2
          ADREQ     R0,key_2
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,key_6
          BEQ       key_press_found

          MOV       R2,#&1E0
          TEQ       R5,R2
          ADREQ     R0,key_3
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,key_7
          BEQ       key_press_found

          MOV       R2,#&1F0
          TEQ       R5,R2
          ADREQ     R0,key_4
          BEQ       key_press_found

          ADD       R2,R2,#1
          TEQ       R5,R2
          ADREQ     R0,key_8
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
          EQUS      "Filer_Run "

.key_file
          EQUZ      "Choices:WinKeys.SetKeys"
          ALIGN

; ----------------------------------------------------------------------------------------------------------------------

.set_key_vars
          STMFD     R13!,{R0-R6,R14}

          MOV       R0,#23
          ADR       R1,key_file
          SWI       "XOS_File"
          LDMVSFD   R13!,{R0-R6,PC}

          TEQ       R0,#1
          LDMNEFD   R13!,{R0-R6,PC}

          ADR       R0,key_file_run
          SWI       "XOS_CLI"

          LDMFD     R13!,{R0-R6,PC}
]
IF debug% THEN
[OPT pass%
          FNReportGen
]
ENDIF
NEXT pass%

SYS "OS_File",10,"<Basic$Dir>."+save_as$,&FFA,,code%,code%+P%

END



DEF FNworkspace(RETURN size%,dim%)
LOCAL ptr%
ptr%=size%
size%+=dim%
=ptr%
