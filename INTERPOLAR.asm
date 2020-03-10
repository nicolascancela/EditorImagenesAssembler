extern _printf

global _interpolar

section .data
align 16
masc1 db 00h, 0FFh, 0FFh, 0FFh, 01h,0FFh, 0FFh, 0FFh, 02h, 0FFh, 0FFh, 0FFh, 03h,0FFh, 0FFh, 0FFh  ;--> 0FFF3h|FFF2h|FFF1h|FFF0h
masc2 db 00h, 04h, 08h, 0Ch, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh,  0FFh, 0FFh, 0FFh, 0FFh ;--> FFFFh|FFFFh|FFFFh|3210h
UnopF dd 1.0


section .text
;UBICACI�N DE LOS PARAMETROS EN LA PILA
;[EBP+8] IMAGEN1
;[EBP+12] IMAGEN2
;[EBP+16] RESULTADO
;[EBP+20] P
;[EBP+24] LONGITUD DE LA IMAGEN

_interpolar:
    PUSH EBP			;ARMO CONTEXTO
    MOV EBP, ESP
    
    MOV EAX, [EBP+8]            ;GUARDO EN EAX EL PUNTERO AL VECTOR DE PIXELES IMG1
    MOV EBX, [EBP+12]           ;GUARDO EN EBX EL PUNTERO AL VECTOR DE PIXELES IMG2
    MOV EDX, [EBP+16]           ;GUARDO EN EDX EL PUNTERO AL VECTOR DE PIXELES RESULTADO
    MOV EDI, [EBP+20]           ;GUARDO EL EDI EL PUNTERO AL VALOR P
    
    MOV ESI, [EBP+24]           ;GUARDO EL LARGO DEL VECTOR EN ESI!
    SHR ESI, 2                  ;DIVIDO ESI POR 4 --> ME DA LA CANTIDAD DE ITERACIONES
    
    ;ARMO P
    MOVD XMM3, EDI            ;GUARDO EN XMM3 EL FLOAT DE PRECISI�N SIMPLE P
    PSHUFD XMM3, XMM3, 00000000 ;APLICO LA MASCARA AL VALOR P --> 000P|000P|000P|000P
    
    MOVD XMM4, [UnopF]          ;COPIO A XMM5 EL 1.0
    PSHUFD XMM4, XMM4, 00000000 ;APLICO LA MASCARA --> 0001.0|0001.0|0001.0|0001.0
    SUBPS XMM4, XMM3            ;RESTO 1.0 - P
    
    ;YA ARMAMOS EL CONTEXTO, AHORA VAMOS A COMENZAR A PROCESAR LA IMAGEN!
    MOV ECX, 0                  ;INICIO EL CONTADOR EN 0!   
    
ciclar:
    CMP ECX, ESI
    JE salir
    
    MOVD XMM1, [EAX+ECX*4]      ;GUARDO 4 BYTES DEL VECTOR IMG1
    MOVD XMM2, [EBX+ECX*4]      ;GUARDO 4 BYTES DEL VECTOR IMG1
    
    PSHUFB XMM1, [masc1]        ;APLICO MASCARA A IMG1 --> 000V3|000V2|000V1|000V0
    PSHUFB XMM2, [masc1]        ;APLICO MASCARA A IMG2 --> 000V3|000V2|000V1|000V0
    
    CVTDQ2PS XMM1, XMM1         ;CONVIERTO LOS VALORES DEL XMM1 EN PUNTO FLOTANTE DE PRECISI�N SIMPLE
    CVTDQ2PS XMM2, XMM2         ;CONVIERTO LOS VALORES DEL XMM1 EN PUNTO FLOTANTE DE PRECISI�N SIMPLE
    
    ;OPERACI�N: r = p � v1 + (1 - p) � v2
    ;P X V1
    MULPS XMM1, XMM3            ;V1 -> XMM1     P -> XMM3
    ;(1-P) X V2
    MULPS XMM2, XMM4            ;V2 -> XMM2     (1-P) -> XMM4
    ;SUMA
    ADDPS XMM1, XMM2
    
    CVTPS2DQ XMM1, XMM1        ;CONVIERTO DE PUNTO FLOTANTE A ENTERO
    PSHUFB XMM1, [masc2]       ;APLICO MASCARA A IMG1 --> 00000|00000|00000|V3V2V1V0
   
    MOVD [EDX+ECX*4], XMM1     ;GUARDO EL PROCESAMIENTO EN EL VECTOR RESULTADO!
    INC ECX   
    JMP ciclar
    
salir:
    MOV ESP, EBP
    POP EBP
    RET