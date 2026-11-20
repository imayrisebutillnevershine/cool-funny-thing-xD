default rel
global _start

section .data
    init_seq    db 27, "[?1049h", 27, "[2J", 27, "[H", 27, "[?25l"
    init_len    equ $ - init_seq
    sync_start  db 27, "[?2026h"
    sync_s_len  equ $ - sync_start
    sync_end    db 27, "[0m", 27, "[?2026l"
    sync_e_len  equ $ - sync_end
    restore_seq db 27, "[0m", 27, "[?25h", 27, "[?1049l"
    restore_len equ $ - restore_seq

    hud_prefix  db 27, "[48;2;18;20;28m", 27, "[38;2;230;210;150m"
                db "WASD: Fly  Arrows/JL/IK: Look  Space: AutoWalk  M: Subpixel/ASCII  P: HD Snap  Q: Quit "
                db 27, "[0m", 27, "[K"
    hud_len     equ $ - hud_prefix

    ppm_path    db "flowers.ppm", 0
    ppm_hdr     db "P6", 10, "960 540", 10, "255", 10
    ppm_hdr_len equ $ - ppm_hdr

    img_w       equ 960
    img_h       equ 540

    sleep_ts:
        dq 0
        dq 22000000

    pfd_fd      dd 0
    pfd_events  dw 1
    pfd_revents dw 0

    cam_x       dd 0.0
    cam_y       dd 0.80
    cam_z       dd -2.30
    cam_yaw     dd 0.0
    cam_pitch   dd -0.15
    time_val    dd 0.0
    auto_walk   dd 1
    ascii_mode  dd 0
    is_hd_pass  dd 0

    yaw_sin     dd 0.0
    yaw_cos     dd 1.0
    pitch_sin   dd -0.1494
    pitch_cos   dd 0.9888

    focal       dd 1.32
    f_img_half_w dd 480.0
    f_img_half_h dd 270.0
    f_img_aspect dd 0.5625

    f_dt        dd 0.025
    f_walk_spd  dd 0.048
    f_move_step dd 0.22
    f_turn_step dd 0.075

    sun_x       dd 0.380
    sun_y       dd 0.300
    sun_z       dd 0.875

    f_zero      dd 0.0
    f_one       dd 1.0
    f_two       dd 2.0
    f_three     dd 3.0
    f_four      dd 4.0
    f_five      dd 5.0
    f_sixteen   dd 16.0
    f_twenty    dd 20.0
    f_half      dd 0.5
    f_0_25      dd 0.25
    f_0_75      dd 0.75
    f_1_5       dd 1.5
    f_255       dd 255.0

    f_t_init    dd 0.12
    f_max_t     dd 25.0
    f_inv_max_t dd 0.040
    f_eps       dd 0.0024
    f_eps_fast  dd 0.0075
    f_norm_eps  dd 0.0032
    f_step_hd   dd 0.50
    f_step_rt   dd 0.68

    f_freq1     dd 0.045
    f_freq2     dd 0.115
    f_freq3     dd 0.55
    f_amp1      dd 0.28
    f_amp2      dd 0.12

    f_cell      dd 0.58
    f_inv_cell  dd 1.7241379
    f_jit_scale dd 0.00088
    f_h_base    dd 0.32
    f_h_scale   dd 0.00095
    f_rot_scale dd 0.00390625
    f_sway_amp  dd 0.080
    f_wind_fx   dd 0.22
    f_wind_fz   dd 0.16

    f_bbox_r    dd 0.27
    f_stem_r    dd 0.012
    f_calyx_r   dd 0.036
    f_calyx_y   dd 0.024
    f_core_r    dd 0.052
    f_core_flat dd 2.25
    f_core_bump dd 28.0
    f_bump_amp  dd 0.0055
    f_stam_r    dd 0.042
    f_stam_th   dd 0.009

    f_pet_r_in  dd 0.034
    f_pet_r_out dd 0.105
    f_pet_lobe  dd 0.068
    f_pet2_r_out dd 0.082
    f_pet2_lobe dd 0.052
    f_pet2_y_off dd 0.014
    f_pet_thick dd 0.013
    f_pet_vein  dd 0.012
    f_pet_cup_a dd 1.45
    f_pet_cup_b dd 2.80
    f_pet_curl  dd 4.20
    f_pet_y_sc  dd 1.65

    f_leaf_y    dd 0.16
    f_leaf_len  dd 0.095
    f_leaf_r    dd 0.013
    f_grass_h   dd 0.23

    f_tiny_eps  dd 0.0001
    f_neg_0_3   dd -0.35
    f_sky_skip  dd 0.88
    f_h_max     dd 0.64
    f_tilt_c    dd 0.955
    f_tilt_s    dd -0.295

    f_amb       dd 0.34
    f_amb_min   dd 0.30
    f_sun_int   dd 1.38
    f_sss_int   dd 0.95
    f_rim_int   dd 0.62
    f_fog_max   dd 0.88
    f_shad_t0   dd 0.038
    f_shad_max  dd 4.2
    f_shad_k    dd 10.0
    f_vol_step  dd 0.65
    f_vol_int   dd 0.048
    f_vol_rt    dd 0.36
    f_ray_freq1 dd 1.35
    f_ray_freq2 dd 2.85
    f_tone_k    dd 0.42
    f_tone_gain dd 1.34
    f_embed_sun dd 0.35

    sky_zen_r   dd 0.13
    sky_zen_g   dd 0.33
    sky_zen_b   dd 0.75

    sky_hor_r   dd 0.98
    sky_hor_g   dd 0.68
    sky_hor_b   dd 0.38

    sun_col_r   dd 1.00
    sun_col_g   dd 0.92
    sun_col_b   dd 0.62

    align 16
    flower_palette:
        dd 1.00, 0.78, 0.04, '@'
        dd 0.96, 0.12, 0.16, '*'
        dd 0.68, 0.32, 1.00, '%'
        dd 1.00, 0.50, 0.76, '*'
        dd 0.16, 0.62, 1.00, '+'
        dd 1.00, 0.42, 0.04, '#'
        dd 0.98, 0.97, 0.90, 'o'
        dd 0.94, 0.16, 0.56, '@'

    grass_r     dd 0.14
    grass_g     dd 0.46
    grass_b     dd 0.10

    grass_tip_r dd 0.48
    grass_tip_g dd 0.80
    grass_tip_b dd 0.16

    stem_r      dd 0.18
    stem_g      dd 0.58
    stem_b      dd 0.16

    core_r      dd 0.96
    core_g      dd 0.64
    core_b      dd 0.06

    core_dark_r dd 0.32
    core_dark_g dd 0.15
    core_dark_b dd 0.05

    stamen_r    dd 1.00
    stamen_g    dd 0.84
    stamen_b    dd 0.15

    align 16
    abs_mask    dd 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF
    neg_mask    dd 0x80000000, 0x80000000, 0x80000000, 0x80000000

section .bss
    ws          resw 4
    dyn_tw      resd 1
    dyn_th      resd 1
    f_dyn_hw    resd 1
    f_dyn_hh    resd 1
    f_dyn_asp   resd 1

    orig_termios resb 64
    new_termios  resb 64
    key_buf      resb 16

    ppm_buf     resb img_w * img_h * 3
    frame_buf   resb 1048576
    out_ptr     resq 1

    cur_rx      resd 1
    cur_ry      resd 1
    cur_rz      resd 1
    hit_x       resd 1
    hit_y       resd 1
    hit_z       resd 1
    hit_t       resd 1
    hit_mat     resd 1
    hit_spec    resd 1
    norm_x      resd 1
    norm_y      resd 1
    norm_z      resd 1
    pix_r       resd 1
    pix_g       resd 1
    pix_b       resd 1
    pix_glyph   resd 1

    top_r       resd 1
    top_g       resd 1
    top_b       resd 1

section .text

_start:
    mov rax, 16
    xor rdi, rdi
    mov rsi, 0x5401
    lea rdx, [orig_termios]
    syscall
    test rax, rax
    js .non_tty_fallback

    call query_terminal_size
    cmp dword [dyn_tw], 20
    jl .non_tty_fallback

    lea rsi, [orig_termios]
    lea rdi, [new_termios]
    mov ecx, 16
    rep movsd
    and dword [new_termios + 12], ~0x000B

    mov rax, 16
    xor rdi, rdi
    mov rsi, 0x5402
    lea rdx, [new_termios]
    syscall

    lea rsi, [init_seq]
    mov rdx, init_len
    call write_all_stdout

.realtime_loop:
    mov dword [pfd_fd], 0
    mov word [pfd_events], 1
    mov word [pfd_revents], 0
    mov rax, 7
    lea rdi, [pfd_fd]
    mov rsi, 1
    xor rdx, rdx
    syscall
    cmp rax, 0
    jle .no_input
    test word [pfd_revents], 1
    jz .no_input

    xor rax, rax
    xor rdi, rdi
    lea rsi, [key_buf]
    mov rdx, 8
    syscall
    cmp rax, 0
    jle .no_input

    movzx eax, byte [key_buf]
    cmp al, 'q'
    je .cleanup_and_exit
    cmp al, 'Q'
    je .cleanup_and_exit
    cmp al, 27
    jne .check_wasd
    cmp rax, 1
    je .cleanup_and_exit
    cmp byte [key_buf + 1], '['
    jne .cleanup_and_exit
    movzx eax, byte [key_buf + 2]
    cmp al, 'A'
    je .pitch_up
    cmp al, 'B'
    je .pitch_down
    cmp al, 'C'
    je .yaw_right
    cmp al, 'D'
    je .yaw_left
    jmp .no_input

.check_wasd:
    cmp al, 'w'
    je .move_fwd
    cmp al, 'W'
    je .move_fwd
    cmp al, 's'
    je .move_back
    cmp al, 'S'
    je .move_back
    cmp al, 'a'
    je .move_left
    cmp al, 'A'
    je .move_left
    cmp al, 'd'
    je .move_right
    cmp al, 'D'
    je .move_right
    cmp al, 'j'
    je .yaw_left
    cmp al, 'l'
    je .yaw_right
    cmp al, 'i'
    je .pitch_up
    cmp al, 'k'
    je .pitch_down
    cmp al, ' '
    je .toggle_autowalk
    cmp al, 'm'
    je .toggle_mode
    cmp al, 'M'
    je .toggle_mode
    cmp al, 'p'
    je .trigger_snap
    cmp al, 'P'
    je .trigger_snap
    jmp .no_input

.move_fwd:
    movss xmm0, [yaw_sin]
    mulss xmm0, [f_move_step]
    addss xmm0, [cam_x]
    movss [cam_x], xmm0
    movss xmm0, [yaw_cos]
    mulss xmm0, [f_move_step]
    addss xmm0, [cam_z]
    movss [cam_z], xmm0
    jmp .no_input

.move_back:
    movss xmm0, [yaw_sin]
    mulss xmm0, [f_move_step]
    movss xmm1, [cam_x]
    subss xmm1, xmm0
    movss [cam_x], xmm1
    movss xmm0, [yaw_cos]
    mulss xmm0, [f_move_step]
    movss xmm1, [cam_z]
    subss xmm1, xmm0
    movss [cam_z], xmm1
    jmp .no_input

.move_left:
    movss xmm0, [yaw_cos]
    mulss xmm0, [f_move_step]
    movss xmm1, [cam_x]
    subss xmm1, xmm0
    movss [cam_x], xmm1
    movss xmm0, [yaw_sin]
    mulss xmm0, [f_move_step]
    addss xmm0, [cam_z]
    movss [cam_z], xmm0
    jmp .no_input

.move_right:
    movss xmm0, [yaw_cos]
    mulss xmm0, [f_move_step]
    addss xmm0, [cam_x]
    movss [cam_x], xmm0
    movss xmm0, [yaw_sin]
    mulss xmm0, [f_move_step]
    movss xmm1, [cam_z]
    subss xmm1, xmm0
    movss [cam_z], xmm1
    jmp .no_input

.yaw_left:
    movss xmm0, [cam_yaw]
    subss xmm0, [f_turn_step]
    movss [cam_yaw], xmm0
    jmp .no_input

.yaw_right:
    movss xmm0, [cam_yaw]
    addss xmm0, [f_turn_step]
    movss [cam_yaw], xmm0
    jmp .no_input

.pitch_up:
    movss xmm0, [cam_pitch]
    addss xmm0, [f_turn_step]
    movss [cam_pitch], xmm0
    jmp .no_input

.pitch_down:
    movss xmm0, [cam_pitch]
    subss xmm0, [f_turn_step]
    movss [cam_pitch], xmm0
    jmp .no_input

.toggle_autowalk:
    xor dword [auto_walk], 1
    jmp .no_input

.toggle_mode:
    xor dword [ascii_mode], 1
    jmp .no_input

.trigger_snap:
    call save_hd_ppm_snapshot
    jmp .no_input

.no_input:
    movss xmm0, [time_val]
    addss xmm0, [f_dt]
    movss [time_val], xmm0

    cmp dword [auto_walk], 0
    je .skip_autowalk
    movss xmm0, [yaw_sin]
    mulss xmm0, [f_walk_spd]
    addss xmm0, [cam_x]
    movss [cam_x], xmm0

    movss xmm0, [yaw_cos]
    mulss xmm0, [f_walk_spd]
    addss xmm0, [cam_z]
    movss [cam_z], xmm0

    movss xmm8, [cam_x]
    movss xmm10, [cam_z]
    call get_terrain_height
    addss xmm0, [f_0_75]
    movss [cam_y], xmm0
.skip_autowalk:

    fld dword [cam_yaw]
    fsincos
    fstp dword [yaw_cos]
    fstp dword [yaw_sin]

    fld dword [cam_pitch]
    fsincos
    fstp dword [pitch_cos]
    fstp dword [pitch_sin]

    call query_terminal_size
    call render_terminal_frame

    lea rsi, [frame_buf]
    mov rdx, [out_ptr]
    sub rdx, rsi
    call write_all_stdout

    mov rax, 35
    lea rdi, [sleep_ts]
    xor rsi, rsi
    syscall

    jmp .realtime_loop

.non_tty_fallback:
    call save_hd_ppm_snapshot
    mov dword [dyn_tw], 100
    mov dword [dyn_th], 36
    call compute_aspect_direct
    call render_terminal_frame

    lea rsi, [frame_buf]
    mov rdx, [out_ptr]
    sub rdx, rsi
    call write_all_stdout

    xor rdi, rdi
    mov rax, 60
    syscall

.cleanup_and_exit:
    mov rax, 16
    xor rdi, rdi
    mov rsi, 0x5402
    lea rdx, [orig_termios]
    syscall

    lea rsi, [restore_seq]
    mov rdx, restore_len
    call write_all_stdout

    xor rdi, rdi
    mov rax, 60
    syscall

write_all_stdout:
    push rbx
    mov rbx, rsi
.w_loop:
    test rdx, rdx
    jle .w_done
    mov rax, 1
    mov rdi, 1
    mov rsi, rbx
    syscall
    cmp rax, 0
    jle .w_done
    add rbx, rax
    sub rdx, rax
    jmp .w_loop
.w_done:
    pop rbx
    ret

query_terminal_size:
    mov rax, 16
    mov rdi, 1
    mov rsi, 0x5413
    lea rdx, [ws]
    syscall
    test rax, rax
    js .default_ws

    movzx eax, word [ws + 2]
    cmp eax, 20
    jl .default_ws
    dec eax
    cmp eax, 180
    jle .ok_w
    mov eax, 180
.ok_w:
    mov [dyn_tw], eax

    movzx ecx, word [ws]
    cmp ecx, 12
    jl .default_ws
    dec ecx
    cmp ecx, 75
    jle .ok_h
    mov ecx, 75
.ok_h:
    mov [dyn_th], ecx
    jmp compute_aspect_direct

.default_ws:
    mov dword [dyn_tw], 100
    mov dword [dyn_th], 36

compute_aspect_direct:
    mov eax, [dyn_tw]
    cvtsi2ss xmm0, eax
    mulss xmm0, [f_half]
    movss [f_dyn_hw], xmm0

    mov eax, [dyn_th]
    cvtsi2ss xmm1, eax
    cmp dword [ascii_mode], 0
    jne .ascii_hh
    movss [f_dyn_hh], xmm1
    jmp .calc_asp
.ascii_hh:
    mulss xmm1, [f_half]
    movss [f_dyn_hh], xmm1
.calc_asp:
    movss xmm2, [f_dyn_hh]
    divss xmm2, [f_dyn_hw]
    cmp dword [ascii_mode], 0
    je .store_asp
    addss xmm2, xmm2
.store_asp:
    movss [f_dyn_asp], xmm2
    ret

render_terminal_frame:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov dword [is_hd_pass], 0
    lea rdi, [frame_buf]

    lea rsi, [sync_start]
    mov ecx, sync_s_len
    rep movsb
    mov [out_ptr], rdi

    xor r12d, r12d
.row_loop:
    mov rdi, [out_ptr]
    mov byte [rdi], 27
    mov byte [rdi + 1], '['
    add rdi, 2
    lea eax, [r12d + 1]
    call append_u8
    mov byte [rdi], ';'
    mov byte [rdi + 1], '1'
    mov byte [rdi + 2], 'H'
    add rdi, 3
    mov [out_ptr], rdi

    xor r13d, r13d
.col_loop:
    cmp dword [ascii_mode], 1
    je .render_ascii_cell

    mov eax, r12d
    add eax, eax
    mov esi, r13d
    call trace_terminal_subpixel

    movss xmm0, [pix_r]
    call tonemap_to_u8
    mov [top_r], eax
    movss xmm0, [pix_g]
    call tonemap_to_u8
    mov [top_g], eax
    movss xmm0, [pix_b]
    call tonemap_to_u8
    mov [top_b], eax

    mov eax, r12d
    add eax, eax
    inc eax
    mov esi, r13d
    call trace_terminal_subpixel

    movss xmm0, [pix_r]
    call tonemap_to_u8
    mov r8d, eax
    movss xmm0, [pix_g]
    call tonemap_to_u8
    mov r9d, eax
    movss xmm0, [pix_b]
    call tonemap_to_u8
    mov r10d, eax

    mov rdi, [out_ptr]
    mov byte [rdi], 27
    mov byte [rdi + 1], '['
    mov byte [rdi + 2], '3'
    mov byte [rdi + 3], '8'
    mov byte [rdi + 4], ';'
    mov byte [rdi + 5], '2'
    mov byte [rdi + 6], ';'
    add rdi, 7

    mov eax, [top_r]
    call append_u8
    mov byte [rdi], ';'
    inc rdi
    mov eax, [top_g]
    call append_u8
    mov byte [rdi], ';'
    inc rdi
    mov eax, [top_b]
    call append_u8

    mov byte [rdi], ';'
    mov byte [rdi + 1], '4'
    mov byte [rdi + 2], '8'
    mov byte [rdi + 3], ';'
    mov byte [rdi + 4], '2'
    mov byte [rdi + 5], ';'
    add rdi, 6

    mov eax, r8d
    call append_u8
    mov byte [rdi], ';'
    inc rdi
    mov eax, r9d
    call append_u8
    mov byte [rdi], ';'
    inc rdi
    mov eax, r10d
    call append_u8
    mov byte [rdi], 'm'
    inc rdi

    mov byte [rdi], 0xE2
    mov byte [rdi + 1], 0x96
    mov byte [rdi + 2], 0x80
    add rdi, 3
    mov [out_ptr], rdi
    jmp .next_col

.render_ascii_cell:
    mov eax, r12d
    mov esi, r13d
    call trace_terminal_subpixel

    movss xmm0, [pix_r]
    call tonemap_to_u8
    mov r8d, eax
    movss xmm0, [pix_g]
    call tonemap_to_u8
    mov r9d, eax
    movss xmm0, [pix_b]
    call tonemap_to_u8
    mov r10d, eax
    mov r11d, [pix_glyph]

    mov rdi, [out_ptr]
    mov byte [rdi], 27
    mov byte [rdi + 1], '['
    mov byte [rdi + 2], '3'
    mov byte [rdi + 3], '8'
    mov byte [rdi + 4], ';'
    mov byte [rdi + 5], '2'
    mov byte [rdi + 6], ';'
    add rdi, 7

    mov eax, r8d
    call append_u8
    mov byte [rdi], ';'
    inc rdi
    mov eax, r9d
    call append_u8
    mov byte [rdi], ';'
    inc rdi
    mov eax, r10d
    call append_u8
    mov byte [rdi], 'm'
    inc rdi

    mov [rdi], r11b
    inc rdi
    mov [out_ptr], rdi

.next_col:
    inc r13d
    cmp r13d, [dyn_tw]
    jl .col_loop

    mov rdi, [out_ptr]
    mov byte [rdi], 27
    mov byte [rdi + 1], '['
    mov byte [rdi + 2], '0'
    mov byte [rdi + 3], 'm'
    mov byte [rdi + 4], 27
    mov byte [rdi + 5], '['
    mov byte [rdi + 6], 'K'
    add rdi, 7
    mov [out_ptr], rdi

    inc r12d
    cmp r12d, [dyn_th]
    jl .row_loop

    mov rdi, [out_ptr]
    mov byte [rdi], 27
    mov byte [rdi + 1], '['
    add rdi, 2
    mov eax, [dyn_th]
    inc eax
    call append_u8
    mov byte [rdi], ';'
    mov byte [rdi + 1], '1'
    mov byte [rdi + 2], 'H'
    add rdi, 3

    lea rsi, [hud_prefix]
    mov ecx, hud_len
    rep movsb

    lea rsi, [sync_end]
    mov ecx, sync_e_len
    rep movsb
    mov [out_ptr], rdi

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

trace_terminal_subpixel:
    cvtsi2ss xmm0, esi
    subss xmm0, [f_dyn_hw]
    divss xmm0, [f_dyn_hw]

    cvtsi2ss xmm1, eax
    subss xmm1, [f_dyn_hh]
    divss xmm1, [f_dyn_hh]
    mulss xmm1, [f_dyn_asp]
    xorps xmm2, xmm2
    subss xmm2, xmm1

    movss xmm3, [focal]
    call setup_camera_ray
    call shade_ray
    ret

save_hd_ppm_snapshot:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov dword [is_hd_pass], 1
    lea r15, [ppm_buf]

    xor r12d, r12d
.hd_y:
    xor r13d, r13d
.hd_x:
    cvtsi2ss xmm0, r13d
    subss xmm0, [f_img_half_w]
    divss xmm0, [f_img_half_w]

    cvtsi2ss xmm1, r12d
    subss xmm1, [f_img_half_h]
    divss xmm1, [f_img_half_h]
    mulss xmm1, [f_img_aspect]
    xorps xmm2, xmm2
    subss xmm2, xmm1

    movss xmm3, [focal]
    call setup_camera_ray
    call shade_ray

    movss xmm0, [pix_r]
    call tonemap_to_u8
    mov [r15], al

    movss xmm0, [pix_g]
    call tonemap_to_u8
    mov [r15 + 1], al

    movss xmm0, [pix_b]
    call tonemap_to_u8
    mov [r15 + 2], al

    add r15, 3
    inc r13d
    cmp r13d, img_w
    jl .hd_x

    inc r12d
    cmp r12d, img_h
    jl .hd_y

    mov rax, 2
    lea rdi, [ppm_path]
    mov rsi, 0101o | 01000o
    mov rdx, 0644o
    syscall
    test rax, rax
    js .hd_done
    mov r14, rax

    mov rax, 1
    mov rdi, r14
    lea rsi, [ppm_hdr]
    mov rdx, ppm_hdr_len
    syscall

    mov rax, 1
    mov rdi, r14
    lea rsi, [ppm_buf]
    mov rdx, img_w * img_h * 3
    syscall

    mov rax, 3
    mov rdi, r14
    syscall

.hd_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

setup_camera_ray:
    movss xmm4, xmm2
    mulss xmm4, [pitch_cos]
    movss xmm5, xmm3
    mulss xmm5, [pitch_sin]
    addss xmm4, xmm5

    movss xmm5, xmm3
    mulss xmm5, [pitch_cos]
    movss xmm6, xmm2
    mulss xmm6, [pitch_sin]
    subss xmm5, xmm6

    movss xmm2, xmm4
    movss xmm3, xmm5

    movss xmm4, xmm0
    mulss xmm4, [yaw_cos]
    movss xmm5, xmm3
    mulss xmm5, [yaw_sin]
    addss xmm4, xmm5

    movss xmm5, xmm3
    mulss xmm5, [yaw_cos]
    movss xmm6, xmm0
    mulss xmm6, [yaw_sin]
    subss xmm5, xmm6

    movss xmm0, xmm4
    movss xmm3, xmm5

    movss xmm4, xmm0
    mulss xmm4, xmm4
    movss xmm5, xmm2
    mulss xmm5, xmm5
    addss xmm4, xmm5
    movss xmm5, xmm3
    mulss xmm5, xmm5
    addss xmm4, xmm5
    sqrtss xmm4, xmm4

    divss xmm0, xmm4
    divss xmm2, xmm4
    divss xmm3, xmm4

    movss [cur_rx], xmm0
    movss [cur_ry], xmm2
    movss [cur_rz], xmm3
    ret

tonemap_to_u8:
    maxss xmm0, [f_zero]
    movss xmm1, xmm0
    mulss xmm1, [f_tone_k]
    addss xmm1, [f_one]
    mulss xmm0, [f_tone_gain]
    divss xmm0, xmm1
    minss xmm0, [f_one]
    mulss xmm0, [f_255]
    cvtss2si eax, xmm0
    ret

fast_sin:
    roundss xmm1, xmm0, 1
    subss xmm0, xmm1
    addss xmm0, xmm0
    subss xmm0, [f_one]
    andps xmm0, [abs_mask]
    addss xmm0, xmm0
    movss xmm1, [f_one]
    subss xmm1, xmm0
    movss xmm2, xmm1
    mulss xmm2, xmm2
    mulss xmm2, [f_half]
    movss xmm0, [f_1_5]
    subss xmm0, xmm2
    mulss xmm0, xmm1
    ret

get_terrain_height:
    movss xmm0, xmm8
    mulss xmm0, [f_freq1]
    call fast_sin
    movss xmm3, xmm0

    movss xmm0, xmm10
    mulss xmm0, [f_freq1]
    addss xmm0, [f_half]
    call fast_sin
    mulss xmm3, xmm0
    mulss xmm3, [f_amp1]

    movss xmm0, xmm10
    mulss xmm0, [f_half]
    addss xmm0, xmm8
    mulss xmm0, [f_freq2]
    call fast_sin
    mulss xmm0, [f_amp2]
    addss xmm3, xmm0

    movss xmm0, xmm3
    ret

shade_ray:
    push rbx
    push r14

    movss xmm7, [f_t_init]
    mov dword [hit_mat], 0
    mov dword [pix_glyph], ' '

    mov ecx, 58
    movss xmm15, [f_step_rt]
    movss xmm14, [f_eps_fast]
    cmp dword [is_hd_pass], 0
    je .march_loop
    mov ecx, 170
    movss xmm15, [f_step_hd]
    movss xmm14, [f_eps]

.march_loop:
    movss xmm8, xmm7
    mulss xmm8, [cur_rx]
    addss xmm8, [cam_x]

    movss xmm9, xmm7
    mulss xmm9, [cur_ry]
    addss xmm9, [cam_y]

    movss xmm10, xmm7
    mulss xmm10, [cur_rz]
    addss xmm10, [cam_z]

    push rcx
    sub rsp, 16
    movss [rsp], xmm14
    movss [rsp + 4], xmm15
    call map_scene
    movss xmm14, [rsp]
    movss xmm15, [rsp + 4]
    add rsp, 16
    pop rcx

    ucomiss xmm6, xmm14
    jb .on_hit

    mulss xmm6, xmm15
    addss xmm7, xmm6

    ucomiss xmm7, [f_max_t]
    ja .on_miss

    dec ecx
    jnz .march_loop

    call get_terrain_height
    movss xmm1, xmm9
    subss xmm1, xmm0
    ucomiss xmm1, [f_sky_skip]
    ja .on_miss
    mov eax, 1
    xor edx, edx

.on_hit:
    movss [hit_x], xmm8
    movss [hit_y], xmm9
    movss [hit_z], xmm10
    movss [hit_t], xmm7
    mov [hit_mat], eax
    mov [hit_spec], edx

    movss xmm14, xmm6

    movss xmm8, [hit_x]
    addss xmm8, [f_norm_eps]
    movss xmm9, [hit_y]
    movss xmm10, [hit_z]
    call map_scene
    subss xmm6, xmm14
    movss [norm_x], xmm6

    movss xmm8, [hit_x]
    movss xmm9, [hit_y]
    addss xmm9, [f_norm_eps]
    movss xmm10, [hit_z]
    call map_scene
    subss xmm6, xmm14
    movss [norm_y], xmm6

    movss xmm8, [hit_x]
    movss xmm9, [hit_y]
    movss xmm10, [hit_z]
    addss xmm10, [f_norm_eps]
    call map_scene
    subss xmm6, xmm14
    movss [norm_z], xmm6

    movss xmm0, [norm_x]
    movss xmm1, [norm_y]
    movss xmm2, [norm_z]
    movss xmm3, xmm0
    mulss xmm3, xmm3
    movss xmm4, xmm1
    mulss xmm4, xmm4
    addss xmm3, xmm4
    movss xmm4, xmm2
    mulss xmm4, xmm4
    addss xmm3, xmm4
    addss xmm3, [f_tiny_eps]
    sqrtss xmm3, xmm3
    divss xmm0, xmm3
    divss xmm1, xmm3
    divss xmm2, xmm3
    movss [norm_x], xmm0
    movss [norm_y], xmm1
    movss [norm_z], xmm2

    mov eax, [hit_mat]
    cmp eax, 1
    je .mat_grass
    cmp eax, 2
    je .mat_stem
    cmp eax, 3
    je .mat_core
    cmp eax, 5
    je .mat_stamen
    cmp eax, 6
    je .mat_inner_petal
    jmp .mat_petal

.mat_grass:
    movss xmm8, [hit_x]
    movss xmm10, [hit_z]
    movss xmm0, xmm8
    addss xmm0, xmm10
    mulss xmm0, [f_freq3]
    call fast_sin
    mulss xmm0, [f_half]
    addss xmm0, [f_half]

    movss xmm1, [grass_tip_r]
    subss xmm1, [grass_r]
    mulss xmm1, xmm0
    addss xmm1, [grass_r]
    movss [pix_r], xmm1

    movss xmm1, [grass_tip_g]
    subss xmm1, [grass_g]
    mulss xmm1, xmm0
    addss xmm1, [grass_g]
    movss [pix_g], xmm1

    movss xmm1, [grass_tip_b]
    subss xmm1, [grass_b]
    mulss xmm1, xmm0
    addss xmm1, [grass_b]
    movss [pix_b], xmm1
    mov dword [pix_glyph], '"'
    jmp .compute_lighting

.mat_stem:
    movss xmm0, [stem_r]
    movss [pix_r], xmm0
    movss xmm0, [stem_g]
    movss [pix_g], xmm0
    movss xmm0, [stem_b]
    movss [pix_b], xmm0
    mov dword [pix_glyph], '|'
    jmp .compute_lighting

.mat_core:
    mov eax, [hit_spec]
    and eax, 3
    cmp eax, 1
    jbe .dark_core
    movss xmm0, [core_r]
    movss [pix_r], xmm0
    movss xmm0, [core_g]
    movss [pix_g], xmm0
    movss xmm0, [core_b]
    movss [pix_b], xmm0
    mov dword [pix_glyph], 'o'
    jmp .compute_lighting
.dark_core:
    movss xmm0, [core_dark_r]
    movss [pix_r], xmm0
    movss xmm0, [core_dark_g]
    movss [pix_g], xmm0
    movss xmm0, [core_dark_b]
    movss [pix_b], xmm0
    mov dword [pix_glyph], 'o'
    jmp .compute_lighting

.mat_stamen:
    movss xmm0, [stamen_r]
    movss [pix_r], xmm0
    movss xmm0, [stamen_g]
    movss [pix_g], xmm0
    movss xmm0, [stamen_b]
    movss [pix_b], xmm0
    mov dword [pix_glyph], ':'
    jmp .compute_lighting

.mat_inner_petal:
    mov eax, [hit_spec]
    and eax, 7
    shl rax, 4
    lea rbx, [flower_palette + rax]
    movss xmm0, [rbx]
    addss xmm0, [f_0_25]
    minss xmm0, [f_one]
    movss [pix_r], xmm0
    movss xmm0, [rbx + 4]
    addss xmm0, [f_0_25]
    minss xmm0, [f_one]
    movss [pix_g], xmm0
    movss xmm0, [rbx + 8]
    mulss xmm0, [f_0_75]
    movss [pix_b], xmm0
    mov eax, [rbx + 12]
    mov [pix_glyph], eax
    jmp .compute_lighting

.mat_petal:
    mov eax, [hit_spec]
    and eax, 7
    shl rax, 4
    lea rbx, [flower_palette + rax]
    movss xmm0, [rbx]
    movss [pix_r], xmm0
    movss xmm0, [rbx + 4]
    movss [pix_g], xmm0
    movss xmm0, [rbx + 8]
    movss [pix_b], xmm0
    mov eax, [rbx + 12]
    mov [pix_glyph], eax

.compute_lighting:
    call cast_shadow
    movss xmm13, xmm0

    movss xmm0, [norm_x]
    mulss xmm0, [sun_x]
    movss xmm1, [norm_y]
    mulss xmm1, [sun_y]
    addss xmm0, xmm1
    movss xmm1, [norm_z]
    mulss xmm1, [sun_z]
    addss xmm0, xmm1

    movss xmm12, xmm0
    addss xmm12, [f_amb]
    maxss xmm12, [f_zero]
    mulss xmm12, [f_0_75]
    mulss xmm12, xmm13
    mulss xmm12, [f_sun_int]

    movss xmm11, [norm_y]
    mulss xmm11, [f_half]
    addss xmm11, [f_half]
    mulss xmm11, [f_amb]

    xorps xmm14, xmm14
    cmp dword [hit_mat], 4
    je .do_sss
    cmp dword [hit_mat], 6
    jne .no_sss
.do_sss:
    movss xmm1, xmm0
    andps xmm1, [abs_mask]
    mulss xmm1, [f_half]
    addss xmm1, [f_half]
    mulss xmm1, [f_sss_int]
    mulss xmm1, xmm13
    movss xmm14, xmm1
.no_sss:

    movss xmm0, [cur_rx]
    mulss xmm0, [norm_x]
    movss xmm1, [cur_ry]
    mulss xmm1, [norm_y]
    addss xmm0, xmm1
    movss xmm1, [cur_rz]
    mulss xmm1, [norm_z]
    addss xmm0, xmm1
    xorps xmm1, xmm1
    subss xmm1, xmm0
    maxss xmm1, [f_zero]
    minss xmm1, [f_one]
    movss xmm0, [f_one]
    subss xmm0, xmm1
    movss xmm1, xmm0
    mulss xmm0, xmm1
    mulss xmm0, xmm1
    mulss xmm0, [f_rim_int]
    mulss xmm0, xmm13

    movss xmm1, xmm11
    addss xmm1, xmm12
    addss xmm1, xmm14

    movss xmm2, [pix_r]
    mulss xmm2, xmm1
    movss xmm3, xmm0
    mulss xmm3, [sun_col_r]
    addss xmm2, xmm3
    movss [pix_r], xmm2

    movss xmm2, [pix_g]
    mulss xmm2, xmm1
    movss xmm3, xmm0
    mulss xmm3, [sun_col_g]
    addss xmm2, xmm3
    movss [pix_g], xmm2

    movss xmm2, [pix_b]
    mulss xmm2, xmm1
    movss xmm3, xmm0
    mulss xmm3, [sun_col_b]
    addss xmm2, xmm3
    movss [pix_b], xmm2

    movss xmm4, [hit_t]
    mulss xmm4, [f_inv_max_t]
    minss xmm4, [f_one]
    mulss xmm4, xmm4
    mulss xmm4, [f_fog_max]

    movss xmm0, [sky_hor_r]
    movss xmm3, [pix_r]
    subss xmm0, xmm3
    mulss xmm0, xmm4
    addss xmm3, xmm0
    movss [pix_r], xmm3

    movss xmm1, [sky_hor_g]
    movss xmm3, [pix_g]
    subss xmm1, xmm3
    mulss xmm1, xmm4
    addss xmm3, xmm1
    movss [pix_g], xmm3

    movss xmm2, [sky_hor_b]
    movss xmm3, [pix_b]
    subss xmm2, xmm3
    mulss xmm2, xmm4
    addss xmm3, xmm2
    movss [pix_b], xmm3

    jmp .apply_god_rays

.on_miss:
    movss xmm0, [f_max_t]
    movss [hit_t], xmm0
    call compute_sky_color
    movss [pix_r], xmm0
    movss [pix_g], xmm1
    movss [pix_b], xmm2

.apply_god_rays:
    call accumulate_god_rays

    movss xmm1, xmm0
    mulss xmm1, [sun_col_r]
    addss xmm1, [pix_r]
    movss [pix_r], xmm1

    movss xmm1, xmm0
    mulss xmm1, [sun_col_g]
    addss xmm1, [pix_g]
    movss [pix_g], xmm1

    movss xmm1, xmm0
    mulss xmm1, [sun_col_b]
    addss xmm1, [pix_b]
    movss [pix_b], xmm1

    pop r14
    pop rbx
    ret

compute_sky_color:
    movss xmm3, [cur_ry]
    maxss xmm3, [f_zero]
    addss xmm3, xmm3
    minss xmm3, [f_one]

    movss xmm0, [sky_zen_r]
    subss xmm0, [sky_hor_r]
    mulss xmm0, xmm3
    addss xmm0, [sky_hor_r]

    movss xmm1, [sky_zen_g]
    subss xmm1, [sky_hor_g]
    mulss xmm1, xmm3
    addss xmm1, [sky_hor_g]

    movss xmm2, [sky_zen_b]
    subss xmm2, [sky_hor_b]
    mulss xmm2, xmm3
    addss xmm2, [sky_hor_b]

    movss xmm4, [cur_rx]
    mulss xmm4, [sun_x]
    movss xmm5, [cur_ry]
    mulss xmm5, [sun_y]
    addss xmm4, xmm5
    movss xmm5, [cur_rz]
    mulss xmm5, [sun_z]
    addss xmm4, xmm5
    maxss xmm4, [f_zero]

    movss xmm5, xmm4
    mulss xmm5, xmm5
    mulss xmm5, xmm5
    mulss xmm5, xmm5

    movss xmm6, xmm5
    mulss xmm6, xmm6
    mulss xmm6, xmm6
    mulss xmm6, xmm6

    movss xmm7, xmm6
    mulss xmm7, xmm7
    mulss xmm7, xmm7

    cmp dword [hit_mat], 0
    jne .add_sun_glow
    mov dword [pix_glyph], ' '
    ucomiss xmm5, [f_half]
    jbe .add_sun_glow
    mov dword [pix_glyph], '.'
    ucomiss xmm6, [f_half]
    jbe .add_sun_glow
    mov dword [pix_glyph], '*'
    ucomiss xmm7, [f_embed_sun]
    jbe .add_sun_glow
    mov dword [pix_glyph], '@'

.add_sun_glow:
    mulss xmm5, [f_0_25]
    mulss xmm6, [f_half]
    addss xmm5, xmm6
    addss xmm5, xmm7

    movss xmm6, xmm5
    mulss xmm6, [sun_col_r]
    addss xmm0, xmm6

    movss xmm6, xmm5
    mulss xmm6, [sun_col_g]
    addss xmm1, xmm6

    movss xmm6, xmm5
    mulss xmm6, [sun_col_b]
    addss xmm2, xmm6
    ret

cast_shadow:
    push rcx
    movss xmm7, [f_shad_t0]
    movss xmm15, [f_one]

    mov ecx, 4
    cmp dword [is_hd_pass], 0
    je .shad_loop
    mov ecx, 14

.shad_loop:
    movss xmm8, xmm7
    mulss xmm8, [sun_x]
    addss xmm8, [hit_x]

    movss xmm9, xmm7
    mulss xmm9, [sun_y]
    addss xmm9, [hit_y]

    movss xmm10, xmm7
    mulss xmm10, [sun_z]
    addss xmm10, [hit_z]

    push rcx
    call map_scene
    pop rcx

    ucomiss xmm6, [f_tiny_eps]
    jb .in_umbra

    movss xmm0, xmm6
    mulss xmm0, [f_shad_k]
    divss xmm0, xmm7
    minss xmm15, xmm0

    addss xmm7, xmm6
    ucomiss xmm7, [f_shad_max]
    ja .shad_done

    dec ecx
    jnz .shad_loop
    jmp .shad_done

.in_umbra:
    movss xmm15, [f_amb_min]
    jmp .shad_done

.shad_done:
    maxss xmm15, [f_amb_min]
    minss xmm15, [f_one]
    movss xmm0, xmm15
    pop rcx
    ret

accumulate_god_rays:
    movss xmm0, [cur_rx]
    mulss xmm0, [sun_x]
    movss xmm1, [cur_ry]
    mulss xmm1, [sun_y]
    addss xmm0, xmm1
    movss xmm1, [cur_rz]
    mulss xmm1, [sun_z]
    addss xmm0, xmm1
    maxss xmm0, [f_zero]
    mulss xmm0, xmm0
    movss xmm14, xmm0
    mulss xmm14, xmm14

    cmp dword [is_hd_pass], 0
    jne .hd_vol_march

    movss xmm0, [cur_rx]
    mulss xmm0, [sun_y]
    movss xmm1, [cur_ry]
    mulss xmm1, [sun_x]
    subss xmm0, xmm1
    movss xmm2, [time_val]
    mulss xmm2, [f_0_25]
    addss xmm0, xmm2
    mulss xmm0, [f_Four_Vol]
    call fast_sin
    maxss xmm0, [f_zero]
    mulss xmm0, xmm14
    mulss xmm0, [f_vol_rt]
    ret

.hd_vol_march:
    xorps xmm15, xmm15
    movss xmm7, [f_half]
    mov ecx, 10
.vol_loop:
    ucomiss xmm7, [hit_t]
    jae .vol_done

    movss xmm8, xmm7
    mulss xmm8, [cur_rx]
    addss xmm8, [cam_x]

    movss xmm9, xmm7
    mulss xmm9, [cur_ry]
    addss xmm9, [cam_y]

    movss xmm0, xmm8
    mulss xmm0, [sun_y]
    movss xmm1, xmm9
    mulss xmm1, [sun_x]
    subss xmm0, xmm1
    movss xmm2, [time_val]
    mulss xmm2, [f_0_25]
    addss xmm0, xmm2
    movss xmm4, xmm0

    mulss xmm0, [f_ray_freq1]
    call fast_sin
    maxss xmm0, [f_zero]
    movss xmm5, xmm0

    movss xmm0, xmm4
    mulss xmm0, [f_ray_freq2]
    call fast_sin
    maxss xmm0, [f_zero]
    addss xmm5, xmm0
    mulss xmm5, xmm5
    addss xmm15, xmm5

    addss xmm7, [f_vol_step]
    dec ecx
    jnz .vol_loop

.vol_done:
    mulss xmm15, xmm14
    mulss xmm15, [f_vol_int]
    movss xmm0, xmm15
    ret

map_scene:
    call get_terrain_height
    movss xmm11, xmm0

    movss xmm6, xmm9
    subss xmm6, xmm11
    mov eax, 1
    xor edx, edx

    movss xmm0, xmm9
    subss xmm0, xmm11
    ucomiss xmm0, [f_sky_skip]
    jbe .eval_flower_cell

    subss xmm0, [f_h_max]
    ucomiss xmm0, xmm6
    jae .done_scene
    movss xmm6, xmm0
    ret

.eval_flower_cell:
    movss xmm0, xmm8
    mulss xmm0, [f_inv_cell]
    roundss xmm1, xmm0, 1
    cvtss2si r8d, xmm1

    movss xmm2, xmm10
    mulss xmm2, [f_inv_cell]
    roundss xmm3, xmm2, 1
    cvtss2si r9d, xmm3

    addss xmm1, [f_half]
    mulss xmm1, [f_cell]
    movss xmm12, xmm8
    subss xmm12, xmm1

    addss xmm3, [f_half]
    mulss xmm3, [f_cell]
    movss xmm13, xmm10
    subss xmm13, xmm3

    imul r8d, 374761393
    imul r9d, 668265263
    add r8d, r9d
    mov r10d, r8d
    shr r10d, 13
    xor r8d, r10d
    imul r8d, 1274126177
    mov r10d, r8d
    shr r10d, 16
    xor r8d, r10d

    mov edx, r8d
    shr edx, 24
    and edx, 7

    movsx r9d, r8b
    cvtsi2ss xmm0, r9d
    mulss xmm0, [f_jit_scale]
    subss xmm12, xmm0

    mov r9d, r8d
    sar r9d, 8
    movsx r9d, r9b
    cvtsi2ss xmm0, r9d
    mulss xmm0, [f_jit_scale]
    subss xmm13, xmm0

    mov r9d, r8d
    shr r9d, 16
    and r9d, 255
    cvtsi2ss xmm14, r9d
    mulss xmm14, [f_h_scale]
    addss xmm14, [f_h_base]

    movss xmm15, xmm9
    subss xmm15, xmm11

    movss xmm0, xmm8
    mulss xmm0, [f_wind_fx]
    movss xmm1, xmm10
    mulss xmm1, [f_wind_fz]
    addss xmm0, xmm1
    subss xmm0, [time_val]
    call fast_sin
    addss xmm0, [f_half]
    mulss xmm0, [f_sway_amp]

    movss xmm1, xmm15
    maxss xmm1, [f_zero]
    minss xmm1, xmm14
    mulss xmm1, xmm1
    mulss xmm1, xmm0
    movss xmm4, xmm12
    subss xmm4, xmm1
    movss xmm1, xmm4

    movss xmm2, xmm1
    mulss xmm2, xmm2
    movss xmm3, xmm13
    mulss xmm3, xmm3
    addss xmm2, xmm3
    addss xmm2, [f_tiny_eps]
    sqrtss xmm2, xmm2

    movss xmm0, xmm2
    subss xmm0, [f_bbox_r]
    ucomiss xmm0, xmm6
    ja .done_scene

    ucomiss xmm15, [f_grass_h]
    ja .eval_stem
    movss xmm3, xmm1
    divss xmm3, xmm2
    minss xmm3, [f_one]
    mulss xmm3, xmm3
    addss xmm3, xmm3
    subss xmm3, [f_one]
    mulss xmm3, xmm3
    addss xmm3, xmm3
    subss xmm3, [f_one]

    movss xmm4, [f_one]
    subss xmm4, xmm3
    mulss xmm4, [f_calyx_r]

    movss xmm5, xmm15
    maxss xmm5, [f_zero]
    mulss xmm5, [f_0_25]
    addss xmm5, [f_pet2_r_out]
    movss xmm0, xmm2
    subss xmm0, xmm5

    mulss xmm0, xmm0
    mulss xmm4, xmm4
    addss xmm0, xmm4
    sqrtss xmm0, xmm0
    subss xmm0, [f_stam_th]
    ucomiss xmm0, xmm6
    jae .eval_stem
    movss xmm6, xmm0
    mov eax, 1

.eval_stem:
    movss xmm3, xmm15
    maxss xmm3, [f_zero]
    minss xmm3, xmm14
    subss xmm3, xmm15
    mulss xmm3, xmm3
    movss xmm4, xmm2
    mulss xmm4, xmm4
    addss xmm3, xmm4
    sqrtss xmm3, xmm3
    subss xmm3, [f_stem_r]

    ucomiss xmm3, xmm6
    jae .chk_leaf
    movss xmm6, xmm3
    mov eax, 2

.chk_leaf:
    movss xmm3, xmm1
    andps xmm3, [abs_mask]
    minss xmm3, [f_leaf_len]
    movss xmm4, xmm1
    andps xmm4, [abs_mask]
    subss xmm4, xmm3
    movss xmm5, xmm15
    subss xmm5, [f_leaf_y]
    mulss xmm3, [f_half]
    subss xmm5, xmm3
    mulss xmm4, xmm4
    mulss xmm5, xmm5
    addss xmm4, xmm5
    movss xmm5, xmm13
    mulss xmm5, xmm5
    addss xmm4, xmm5
    sqrtss xmm4, xmm4
    subss xmm4, [f_leaf_r]

    ucomiss xmm4, xmm6
    jae .chk_calyx
    movss xmm6, xmm4
    mov eax, 2

.chk_calyx:
    movss xmm5, xmm15
    subss xmm5, xmm14
    movss xmm3, xmm5
    addss xmm3, [f_calyx_y]
    mulss xmm3, [f_two]
    mulss xmm3, xmm3
    movss xmm4, xmm2
    mulss xmm4, xmm4
    addss xmm3, xmm4
    sqrtss xmm3, xmm3
    subss xmm3, [f_calyx_r]
    ucomiss xmm3, xmm6
    jae .chk_blossom
    movss xmm6, xmm3
    mov eax, 2

.chk_blossom:
    movss xmm3, xmm5
    mulss xmm3, [f_tilt_c]
    movss xmm4, xmm13
    mulss xmm4, [f_tilt_s]
    subss xmm3, xmm4

    movss xmm4, xmm13
    mulss xmm4, [f_tilt_c]
    movss xmm0, xmm5
    mulss xmm0, [f_tilt_s]
    addss xmm4, xmm0

    mov r9d, r8d
    shr r9d, 11
    and r9d, 255
    cvtsi2ss xmm0, r9d
    mulss xmm0, [f_rot_scale]
    movss xmm12, xmm1
    movss xmm13, xmm3
    movss xmm15, xmm4

    call fast_sin
    movss xmm5, xmm0
    mov r9d, r8d
    shr r9d, 11
    and r9d, 255
    cvtsi2ss xmm0, r9d
    mulss xmm0, [f_rot_scale]
    addss xmm0, [f_0_25]
    call fast_sin

    movss xmm1, xmm12
    mulss xmm1, xmm0
    movss xmm2, xmm15
    mulss xmm2, xmm5
    subss xmm1, xmm2

    movss xmm4, xmm12
    mulss xmm4, xmm5
    movss xmm2, xmm15
    mulss xmm2, xmm0
    addss xmm4, xmm2

    movss xmm3, xmm13

    movss xmm0, xmm1
    mulss xmm0, xmm0
    movss xmm2, xmm4
    mulss xmm2, xmm2
    addss xmm0, xmm2
    addss xmm0, [f_tiny_eps]
    sqrtss xmm0, xmm0
    movss xmm14, xmm0

    movss xmm12, xmm1
    movss xmm15, xmm4

    movss xmm0, xmm12
    mulss xmm0, [f_core_bump]
    call fast_sin
    movss xmm5, xmm0

    movss xmm0, xmm15
    mulss xmm0, [f_core_bump]
    call fast_sin
    mulss xmm5, xmm0
    mulss xmm5, [f_bump_amp]

    movss xmm2, xmm3
    mulss xmm2, [f_core_flat]
    mulss xmm2, xmm2
    movss xmm4, xmm14
    mulss xmm4, xmm4
    addss xmm4, xmm2
    sqrtss xmm4, xmm4
    subss xmm4, [f_core_r]
    subss xmm4, xmm5

    ucomiss xmm4, xmm6
    jae .chk_stamen_ring
    movss xmm6, xmm4
    mov eax, 3

.chk_stamen_ring:
    movss xmm0, xmm14
    subss xmm0, [f_stam_r]
    mulss xmm0, xmm0
    movss xmm2, xmm3
    subss xmm2, [f_pet_vein]
    mulss xmm2, xmm2
    addss xmm0, xmm2
    sqrtss xmm0, xmm0
    subss xmm0, [f_stam_th]
    ucomiss xmm0, xmm6
    jae .eval_double_corolla
    movss xmm6, xmm0
    mov eax, 5

.eval_double_corolla:
    movss xmm2, xmm12
    divss xmm2, xmm14

    test edx, 1
    jnz .five_petal_wave

    movss xmm4, xmm2
    mulss xmm4, xmm4
    addss xmm4, xmm4
    subss xmm4, [f_one]
    mulss xmm4, xmm4
    addss xmm4, xmm4
    subss xmm4, [f_one]
    mulss xmm4, xmm4
    addss xmm4, xmm4
    subss xmm4, [f_one]
    movss xmm13, [f_pet_cup_a]
    jmp .eval_outer_petals

.five_petal_wave:
    movss xmm4, xmm2
    mulss xmm4, xmm4
    movss xmm5, xmm4
    mulss xmm5, [f_sixteen]
    subss xmm5, [f_twenty]
    mulss xmm5, xmm4
    addss xmm5, [f_five]
    mulss xmm5, xmm2
    movss xmm4, xmm5
    movss xmm13, [f_pet_cup_b]

.eval_outer_petals:
    movss xmm15, xmm4

    maxss xmm4, [f_neg_0_3]
    mulss xmm4, [f_pet_lobe]
    addss xmm4, [f_pet_r_out]

    movss xmm2, xmm14
    subss xmm2, xmm4
    maxss xmm2, [f_zero]
    movss xmm5, [f_pet_r_in]
    subss xmm5, xmm14
    maxss xmm5, [f_zero]
    addss xmm2, xmm5

    movss xmm5, xmm14
    mulss xmm5, xmm14
    movss xmm0, xmm5
    mulss xmm0, xmm14
    mulss xmm0, [f_pet_curl]
    mulss xmm5, xmm13
    subss xmm5, xmm0

    movss xmm0, xmm15
    mulss xmm0, [f_pet_vein]
    subss xmm5, xmm0

    movss xmm0, xmm3
    subss xmm0, xmm5
    mulss xmm0, [f_pet_y_sc]

    mulss xmm2, xmm2
    mulss xmm0, xmm0
    addss xmm2, xmm0
    sqrtss xmm2, xmm2
    subss xmm2, [f_pet_thick]

    ucomiss xmm2, xmm6
    jae .eval_inner_petals
    movss xmm6, xmm2
    mov eax, 4

.eval_inner_petals:
    movss xmm4, xmm15
    xorps xmm4, [neg_mask]
    maxss xmm4, [f_neg_0_3]
    mulss xmm4, [f_pet2_lobe]
    addss xmm4, [f_pet2_r_out]

    movss xmm2, xmm14
    subss xmm2, xmm4
    maxss xmm2, [f_zero]
    movss xmm5, [f_pet_r_in]
    subss xmm5, xmm14
    maxss xmm5, [f_zero]
    addss xmm2, xmm5

    movss xmm5, xmm14
    mulss xmm5, xmm14
    mulss xmm5, xmm13
    mulss xmm5, [f_1_5]
    movss xmm0, xmm3
    subss xmm0, [f_pet2_y_off]
    subss xmm0, xmm5
    mulss xmm0, [f_pet_y_sc]

    mulss xmm2, xmm2
    mulss xmm0, xmm0
    addss xmm2, xmm0
    sqrtss xmm2, xmm2
    subss xmm2, [f_pet_thick]

    ucomiss xmm2, xmm6
    jae .done_scene
    movss xmm6, xmm2
    mov eax, 6

.done_scene:
    ret

append_u8:
    push rbx
    push rdx
    movzx eax, al
    cmp eax, 100
    jb .two_digits
    xor edx, edx
    mov ebx, 100
    div ebx
    add al, '0'
    mov [rdi], al
    inc rdi
    mov eax, edx
    xor edx, edx
    mov ebx, 10
    div ebx
    add al, '0'
    mov [rdi], al
    inc rdi
    add dl, '0'
    mov [rdi], dl
    inc rdi
    pop rdx
    pop rbx
    ret

.two_digits:
    cmp eax, 10
    jb .one_digit
    xor edx, edx
    mov ebx, 10
    div ebx
    add al, '0'
    mov [rdi], al
    inc rdi
    add dl, '0'
    mov [rdi], dl
    inc rdi
    pop rdx
    pop rbx
    ret

.one_digit:
    add al, '0'
    mov [rdi], al
    inc rdi
    pop rdx
    pop rbx
    ret

section .rodata
    f_Four_Vol  dd 3.5
