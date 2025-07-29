.data
    buffer:         .space 1024     # Buffer de 1024 bytes (1KB)
    buffer_size:    .word 1024      # Tamaño del buffer
    head:          .word 0         # Índice de escritura
    tail:          .word 0         # Índice de lectura
    count:         .word 0         # Contador de elementos en el buffer
    
    prompt:        .asciiz "Ingrese caracteres (20 segundos):\n"
    timeout_msg:   .asciiz "\nTiempo terminado. Contenido del buffer:\n"
    newline:       .asciiz "\n"
    
    # Para el temporizador
    start_time:    .word 0
    current_time:  .word 0
    duration:      .word 20000      # 20 segundos en milisegundos

.text
.globl main

main:
    # Inicialización
    la $s0, buffer         # $s0 = dirección del buffer
    lw $s1, buffer_size    # $s1 = tamaño del buffer
    sw $zero, head         # Inicializar head a 0
    sw $zero, tail         # Inicializar tail a 0
    sw $zero, count        # Inicializar count a 0

main_loop:
    # Mostrar mensaje inicial
    la $a0, prompt
    li $v0, 4
    syscall
    
    # Obtener tiempo inicial (syscall 30)
    li $v0, 30
    syscall
    sw $a0, start_time
    
input_loop:
    # Verificar si ha pasado el tiempo
    li $v0, 30
    syscall
    sw $a0, current_time
    lw $t0, start_time
    lw $t1, current_time
    lw $t2, duration
    sub $t3, $t1, $t0      # Tiempo transcurrido
    bge $t3, $t2, timeout  # Si >= 20000ms, salir
    
    # Intentar leer un carácter (syscall 12 con tiempo de espera)
    li $v0, 12
    syscall
    
    # Si no hay entrada, continuar
    beq $v0, $zero, input_loop
    
    # Guardar el carácter en el buffer
    move $a0, $v0
    jal put_buffer
    
    j input_loop

timeout:
    # Mostrar mensaje de tiempo terminado
    la $a0, timeout_msg
    li $v0, 4
    syscall
    
    # Imprimir contenido del buffer
    jal print_buffer
    
    # Vaciar el buffer
    jal clear_buffer
    
    # Repetir el ciclo
    j main_loop

# Función para agregar un carácter al buffer circular
put_buffer:
    # $a0 = carácter a agregar
    lw $t0, count
    lw $t1, buffer_size
    bge $t0, $t1, buffer_full  # Si buffer lleno, no hacer nada
    
    lw $t2, head
    add $t3, $s0, $t2         # Calcular posición en buffer
    sb $a0, 0($t3)            # Almacenar carácter
    
    # Actualizar head (circular)
    addi $t2, $t2, 1
    rem $t2, $t2, $s1         # head = (head + 1) % buffer_size
    sw $t2, head
    
    # Incrementar count
    lw $t0, count
    addi $t0, $t0, 1
    sw $t0, count
    
buffer_full:
    jr $ra

# Función para imprimir el contenido del buffer
print_buffer:
    lw $t0, tail
    lw $t1, head
    lw $t2, count
    beqz $t2, empty_buffer    # Si count == 0, no hay nada que imprimir
    
print_loop:
    beqz $t2, end_print       # Si count == 0, terminar
    
    # Obtener carácter
    add $t3, $s0, $t0         # Calcular posición en buffer
    lb $a0, 0($t3)            # Cargar carácter
    
    # Imprimir carácter
    li $v0, 11
    syscall
    
    # Actualizar tail (circular)
    addi $t0, $t0, 1
    rem $t0, $t0, $s1         # tail = (tail + 1) % buffer_size
    sw $t0, tail
    
    # Decrementar count
    addi $t2, $t2, -1
    sw $t2, count
    
    j print_loop

empty_buffer:
    la $a0, newline
    li $v0, 4
    syscall
    
end_print:
    jr $ra

# Función para vaciar el buffer
clear_buffer:
    sw $zero, head
    sw $zero, tail
    sw $zero, count
    jr $ra