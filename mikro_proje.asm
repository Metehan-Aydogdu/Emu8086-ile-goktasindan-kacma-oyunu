org 100h

.data
    ; --- Oyuncu Degiskenleri ---
    p_x     dw 160
    p_y     dw 180
    p_old_x dw 160
    p_old_y dw 180
    p_size  dw 6

    has_shield db 0  ;oyuncuda kalkan var mi

    ; --- Asteroid Dizileri ---
    AST_COUNT equ 5
    ast_x      dw 115, 135, 155, 175, 195
    ast_y      dw 0, -40, -80, -120, -160
    ast_size   dw 4, 8, 12, 10, 5
    ast_speeds dw 18, 22, 35, 27, 14
    ast_colors db 07h, 08h, 07h, 08h, 07h

    ; --- Kalkan Degiskenleri ---
    sh_x     dw 150
    sh_y     dw -20
    sh_active db 0
    sh_timer  dw 0

    msg_gameover db "GAME OVER! Yeniden baslatmak icin tusa basin...$"
    msg_title    db 0Eh, "** ASTEROIDDE KACIS **", 07h, "$"
    msg_subtitle db 07h, "Asteroidlerden kacarak hayatta kal!", 07h, "$"
    msg_controls db 0Ah, "[ A ] Sol    [ D ] Sag", 07h, "$"
    msg_start    db 0Fh, "Baslamak icin herhangi bir tusa basin...", 07h, "$"

.code
start:
    ; --- METIN MODUNDA BASLIK EKRANI ---
    mov ax, 03h
    int 10h

    mov ah, 06h
    mov al, 0
    mov bh, 1Fh
    mov cx, 0000h
    mov dx, 184Fh
    int 10h

    mov ah, 02h
    mov bh, 0
    mov dh, 8
    mov dl, 31
    int 10h
    mov ah, 09h
    mov dx, offset msg_title
    int 21h

    mov ah, 02h
    mov dh, 10
    mov dl, 28
    int 10h
    mov ah, 09h
    mov dx, offset msg_subtitle
    int 21h

    mov ah, 02h
    mov dh, 13
    mov dl, 27
    int 10h
    mov ah, 09h
    mov dx, offset msg_controls
    int 21h

    mov ah, 02h
    mov dh, 16
    mov dl, 24
    int 10h
    mov ah, 09h
    mov dx, offset msg_start
    int 21h

    mov ah, 00h
    int 16h

    ; --- GRAFIK MODU---
    mov ax, 13h
    int 10h

    ; --- BASLANGICTA ASTEROIDLERI DAGITARAK YERLESTUR ---
    
    mov si, 0
    mov ast_y[si], 0
    call get_random_ast_si

    mov si, 2
    mov ast_y[si], -40
    call get_random_ast_si

    mov si, 4
    mov ast_y[si], -80
    call get_random_ast_si

    mov si, 6
    mov ast_y[si], -120
    call get_random_ast_si

    mov si, 8
    mov ast_y[si], -160
    call get_random_ast_si

    ; Sol cizgi 
    mov al, 06h
    mov cx, 90
    mov dx, 0
draw_line_l:
    mov ah, 0Ch
    int 10h
    inc dx
    cmp dx, 200
    jne draw_line_l

    ; Sag cizgi
    mov cx, 230
    mov dx, 0
draw_line_r:
    mov ah, 0Ch
    int 10h
    inc dx
    cmp dx, 200
    jne draw_line_r

game_loop:
    call check_input

    ; Eski konumu sil
    mov al, 00h
    mov cx, p_old_x
    mov dx, p_old_y
    mov bx, p_size
    call draw_block

    ; Yeni konumu kaydet
    mov ax, p_x
    mov p_old_x, ax
    mov ax, p_y
    mov p_old_y, ax

    ; Oyuncuyu ciz
    mov al, 0Fh
    cmp has_shield, 1
    jne draw_player_now
    mov al, 0Bh
draw_player_now:
    mov cx, p_x
    mov dx, p_y
    mov bx, p_size
    call draw_block

    ; Oyuncu hareket sonrasi carpisma kontrolu
    mov si, 0
    mov cx, AST_COUNT
player_move_col_loop:
    push cx
    call check_collision_si
    cmp al, 1
    jne player_move_no_hit

    pop cx
    cmp has_shield, 1
    je player_move_use_shield
    jmp game_over_screen

player_move_use_shield:
    mov has_shield, 0
    mov ast_y[si], 0
    call get_random_ast_si
    jmp player_move_col_done

player_move_no_hit:
    pop cx
    add si, 2
    loop player_move_col_loop

player_move_col_done:

    ; --- ASTEROID DONGUSU ---
    mov si, 0
    mov cx, AST_COUNT

ast_update_loop:
    push cx
    push si

    ; Sil
    mov al, 00h
    mov cx, ast_x[si]
    mov dx, ast_y[si]
    mov bx, ast_size[si]
    cmp bx, 0
    je ast_skip_erase
    call draw_block
ast_skip_erase:

    ; Guncelle: Y ekseni
    mov ax, ast_y[si]
    add ax, ast_speeds[si]
    mov ast_y[si], ax

    ; Ekran disi kontrol
    cmp ast_y[si], 195
    jl no_res
    mov ast_y[si], 0
    call get_random_ast_si
no_res:

    ; Carpisma kontrolu
    call check_collision_si
    cmp al, 1
    jne ast_draw_step
    jmp player_dead_check

ast_draw_step:
    push si
    shr si, 1
    mov al, ast_colors[si]
    pop si
    mov cx, ast_x[si]
    mov dx, ast_y[si]
    mov bx, ast_size[si]
    cmp bx, 0
    je ast_skip_draw
    call draw_block
ast_skip_draw:

    pop si
    pop cx
    add si, 2
    loop ast_update_loop

; --- KALKAN hareketleri ---
handle_shield:
    cmp sh_active, 1
    je process_active_shield

    inc sh_timer
    cmp sh_timer, 3
    jl draw_player_section

    mov sh_timer, 0
    mov sh_active, 1
    mov sh_y, 0
    call get_random_sh_x
    jmp draw_player_section

process_active_shield:
    mov al, 00h
    mov cx, sh_x
    mov dx, sh_y
    mov bx, 5
    call draw_block

    add sh_y, 20
    cmp sh_y, 195
    jl check_shield_hit

    mov sh_active, 0
    jmp draw_player_section

check_shield_hit:
    call check_shield_collision
    cmp al, 1
    jne draw_shield_visible

    mov has_shield, 1
    mov sh_active, 0
    jmp draw_player_section

draw_shield_visible:
    mov al, 09h
    mov cx, sh_x
    mov dx, sh_y
    mov bx, 5
    call draw_block

draw_player_section:
    mov al, 0Fh
    cmp has_shield, 1
    jne p_final_draw
    mov al, 0Bh
p_final_draw:
    mov cx, p_x
    mov dx, p_y
    mov bx, p_size
    call draw_block

    ; Gecikme
    mov cx, 020h
delay_game: loop delay_game
    jmp game_loop

; --- DURUM ETIKETLERI ---
player_dead_check:
    cmp has_shield, 1
    je use_shield_logic

    pop si
    pop cx
    jmp game_over_screen

use_shield_logic:
    pop si
    pop cx

    mov has_shield, 0
    mov ast_y[si], 0
    call get_random_ast_si

    add si, 2
    loop ast_update_loop
    jmp handle_shield


; FONKSiYONLAR


; draw_block: AL=renk, CX=x, DX=y, BX=genislik ve yukseklik
draw_block proc
    pusha
    push es

    ; --- 1. BOÞLUK KONTROLÜ ---
    cmp bx, 0           ; Boyut 0 ise çizme
    je db_exit

    ; --- 2. Y KOORDÝNATI KONTROLÜ---
   
    cmp dx, 0
    jl db_exit           
    cmp dx, 199
    ja db_exit          

    ; --- 3. X KOORDÝNATI KONTROLÜ (SOL VE SAÐ SINIR) ---
    
    cmp cx, 91
    jb db_exit          
    
    cmp cx, 319         
    ja db_exit

    ; --- ÇÝZÝM ÝÞLEMÝ BAÞLIYOR ---
    mov si, ax          ; Renk deðerini sakla
    mov ax, 0A000h
    mov es, ax
    
    mov ax, 320
    mul dx              
    add ax, cx          
    mov di, ax
    
    mov dx, bx          
    mov ax, si         
    
db_y:
    mov cx, bx          
    push di
    rep stosb           
    pop di
    add di, 320        
    dec dx
    jnz db_y

db_exit:
    pop es
    popa
    ret
draw_block endp

; check_input: A=sol, D=sag hareket
check_input proc
    mov ah, 01h
    int 16h
    jz no_key
    mov ah, 00h
    int 16h
    cmp al, 'a'
    je move_l
    cmp al, 'd'
    je move_r
    ret

move_l:
    cmp p_x, 105
    jb no_key          ; isaretisiz: sol sinir kontrol
    sub p_x, 15
    ret

move_r:
    cmp p_x, 210
    ja no_key          ; isaretisiz: sag sinir kontrol
    add p_x, 15
no_key:
    ret
check_input endp

get_random_ast_si proc
    push ax
    push bx
    push cx
    push dx

    ; --- Tek seferde rastgele tohum al ---
    mov ah, 00h
    int 1Ah             
    mov ax, dx          
    xor ax, cx          
    add ax, si          

    ; --- Rastgele X: 120 ile 210 arasi ---
    push ax             
    mov bx, 91         
    xor dx, dx          
    div bx              
    add dx, 120         
    mov ast_x[si], dx
    pop ax              

    ; --- Rastgele hiz: 15-35 arasi ---
   
    rol ax, 3          
    mov bx, 21         
    xor dx, dx
    div bx              
    add dx, 15          
    mov ast_speeds[si], dx

    ; --- Ek Sýnýr Kontrolleri ---
    cmp ast_x[si], 210
    jbe check_low
    mov ast_x[si], 210
check_low:
    cmp ast_x[si], 120
    jae exit_rand
    mov ast_x[si], 120

exit_rand:
    pop dx             
    pop cx
    pop bx
    pop ax
    ret
get_random_ast_si endp

; get_random_sh_x: kalkan icin rastgele X atar (120-210)
get_random_sh_x proc
    push ax
    push bx
    push dx

    mov ah, 00h
    int 1Ah
    mov ax, dx
    xor ax, cx

    mov bx, 91
    xor dx, dx
    div bx
    mov ax, dx
    add ax, 120

    cmp ax, 210
    jb sh_x_ok
    mov ax, 210
sh_x_ok:
    mov sh_x, ax

    pop dx
    pop bx
    pop ax
    ret
get_random_sh_x endp

; check_collision_si: si indeksli asteroid ile oyuncu carpisma


check_collision_si proc
    push bx
    push cx
    push dx

    ; Oyuncu sag kenari < asteroid sol kenari?
    mov ax, p_x
    add ax, p_size
    cmp ax, ast_x[si]
    jb no_hit           

    ; Asteroid sag kenari < oyuncu sol kenari?
    mov ax, ast_x[si]
    add ax, ast_size[si]
    cmp ax, p_x
    jb no_hit           

    ; Oyuncu alt kenari < asteroid ust kenari?
    mov ax, p_y
    add ax, p_size
    cmp ax, ast_y[si]
    jb no_hit          

    ; Asteroid alt kenari < oyuncu ust kenari?
    mov ax, ast_y[si]
    add ax, ast_size[si]
    cmp ax, p_y
    jb no_hit           

    pop dx
    pop cx
    pop bx
    mov al, 1
    ret
no_hit:
    pop dx
    pop cx
    pop bx
    mov al, 0
    ret
check_collision_si endp

; check_shield_collision: oyuncu kalkan powerup'ina dokundu mu?
check_shield_collision proc
    push bx
    push cx
    push dx

    cmp sh_active, 0
    je no_s

    mov ax, p_x
    add ax, p_size
    cmp ax, sh_x
    jb no_s            

    mov ax, sh_x
    add ax, 10
    cmp ax, p_x
    jb no_s            

    mov ax, p_y
    add ax, p_size
    cmp ax, sh_y
    jb no_s           

    mov ax, sh_y
    add ax, 10
    cmp ax, p_y
    jb no_s             

    mov al, 1
    pop dx
    pop cx
    pop bx
    ret
no_s:
    pop dx
    pop cx
    pop bx
    mov al, 0
    ret
check_shield_collision endp

game_over_screen:
    mov ax, 03h
    int 10h

    mov ah, 06h
    mov al, 0
    mov bh, 4Fh
    mov cx, 0000h
    mov dx, 184Fh
    int 10h

    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 17
    int 10h
    mov ah, 09h
    mov dx, offset msg_gameover
    int 21h

    mov ah, 00h
    int 16h
    jmp start

end start