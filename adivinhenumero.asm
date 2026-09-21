# SSC0902 - Organizacao e Arquitetura de Computadores
# 1º Trabalho Pratico: Jogo "Adivinhe o Numero"

# Integrantes do grupo:
# Adryen Mendes da Silva     -- NUSP:16830145
# Ítallo Kauê Barbosa Santos -- NUSP:16839029
# Nátalia Yumi Watanabe      -- NUSP:13725566

# Mensagens que serão exibidas ao jogador
.data
    msg_bem_vindo:      .asciz "Bem-vindo ao jogo Adivinhe o Numero!\n"
    msg_instrucoes:     .asciz "O computador escolheu um numero entre 1 e 100.\n"
    msg_pedir_semente:  .asciz "Digite um numero inteiro para a semente (RNG): "
    msg_pedir_palpite:  .asciz "\nDigite seu palpite: "
    msg_invalido:	 .asciz "Palpite fora da faixa! Digite um numero entre 1 a 100\n"
    msg_alto:     	 .asciz "Seu palpite eh maior que o numero secreto\n"
    msg_baixo:    	 .asciz "Seu palpite eh menor que o numero secreto\n"
    msg_correto:        .asciz "Correto! Voce acertou!\n"
    msg_tentativas:     .asciz "Total de tentativas: "
    msg_lista:   	 .asciz "Seus palpites foram: "
    msg_espaco:         .asciz " "
    msg_newline:        .asciz "\n"
    msg_erro_heap:	 .asciz "Falha ao alocar memoria na heap\n"
# Variaveis globais
# Nó da lista = [valor (4 bytes) & ponteiro para o próximo (4 byte)]
    semente:           .word 0
    num_secreto:       .word 0
    tentativas_cont:   .word 0
    head_lista:        .word 0
    tail_lista:        .word 0

.text
.globl main

# Mostra a mensagem de boa-vindas e instruções iniciais, além disso sorteia
# o numero secreto, roda o laço e finaliza.
main:
    addi sp, sp, -16	# Prologo:reserva espaço na pilha
    sw ra, 12(sp)	# Salva o endereço de retorno
    sw s1, 8(sp)	# Preserva o valor do chamador
    
    li a7, 4
    la a0, msg_bem_vindo
    ecall
    la a0, msg_instrucoes
    ecall
    
    jal ra, ler_semente
    jal ra, gerar_numero
    sw a0, num_secreto, t0	# Guarda o número sorteado

# Cria um loop que dá dica sobre o numero e só acaba quando 
# o numero for acertado, mostrando todos os palpites. 
jogo_loop:
    jal ra, ler_palpite
    mv s1, a0

    lw t0, tentativas_cont	
    addi t0, t0, 1
    sw t0, tentativas_cont, t1

    mv a0, s1               
    jal ra, inserir_lista

    mv a0, s1    
    lw a1, num_secreto
    jal ra, verificar_palpite
    beq a0, zero, jogo_loop

    li a7, 4
    la a0, msg_correto
    ecall
    
    la a0, msg_tentativas
    ecall
    li a7, 1
    lw a0, tentativas_cont
    ecall
    
    li a7, 4
    la a0, msg_newline
    ecall
    la a0, msg_lista
    ecall
    
    jal ra, imprimir_lista
    li a7, 10
    lw s1, 8(sp)	# Restaura os registradores salvos
    lw ra, 12(sp)
    addi sp, sp, 16
    ecall

# PROCEDIMENTOS
# Pede o inteiro para o RNG
ler_semente:
    li a7, 4
    la a0, msg_pedir_semente
    ecall
    li a7, 5
    ecall
    sw a0, semente, t0
    ret


# Gera o número secreto a partir da seguinte fórmula: X(n+1) = (a * Xn + c) % m
gerar_numero:
    lw t0, semente
    li t1, 1103515245       # a
    li t2, 12345            # c
    mul t0, t0, t1
    add t0, t0, t2
    
    li t1, 0x7FFFFFFF       # Mascara para o modulo 2^31 (mantem 31 bits)
    and t0, t0, t1          # resulta em modulo 2^31
    sw t0, semente, t1      # atualiza semente para chamada seguinte
    srli t0, t0, 16	    # melhora a qualidade do sorteio, usando os bits altos, já que os bits baixos tem período curto.
    
    li t1, 100
    rem t0, t0, t1          # (0 a 99)
    addi a0, t0, 1          # (1 a 100)
    ret


# Lê a entrada do palpite e confere se ele é um numero possível (1 a 100)
ler_palpite:
    li a7, 4
    la a0, msg_pedir_palpite
    ecall
    li a7, 5
    ecall
    li t0, 1
    blt a0, t0, palpite_invalido
    li t0, 100
    bgt a0, t0, palpite_invalido
    ret
palpite_invalido:
    li a7, 4
    la a0, msg_invalido
    ecall
    j ler_palpite

# Compara o número e dá um feedback
# Entrada: a0 = palpite, a1 = numero secreto
# Saida:   a0 = 1 se acertou, 0 caso contrario (imprime a dica)
verificar_palpite:
    beq a0, a1, palpite_correto
    blt a0, a1, palpite_baixo
    li a7, 4
    la a0, msg_alto
    ecall
    li a0, 0
    ret
palpite_baixo:
    li a7, 4
    la a0, msg_baixo
    ecall
    li a0, 0
    ret
palpite_correto:
    li a0, 1
    ret


# Aloca 8 bytes na heap e confere se não há erro nela
# (4 p valor, 4 p next)
novo_no:
    mv t2, a0
    li a7, 9
    li a0, 8
    ecall
    
    beq a0, zero, erro_heap
    sw t2, 0(a0)
    sw zero, 4(a0)
    ret
erro_heap:
    li a7, 4
    la a0, msg_erro_heap
    ecall
    li a7, 10
    ecall
    
# Adiciona o palpite ao final da lista ligada
inserir_lista:
    addi sp, sp, -16	     # os 16 bytes mantêm o alinhamento da pilha exigido pela ABI
    sw ra, 12(sp)           # salva endereço de retorno
    
    jal ra, novo_no         # cria o nó, endereço em a0
    mv t0, a0               # t0 = novo nó
    
    lw t1, head_lista
    bne t1, zero, adicionar_no_fim
    
    # se a lista estiver vazia (head == 0)
    sw t0, head_lista, t2
    sw t0, tail_lista, t2
    j fim_insercao

adicionar_no_fim:
    lw t1, tail_lista       # pega o último nó atual
    sw t0, 4(t1)            # ultimo->next = novo_no
    sw t0, tail_lista, t2   # tail = novo_no

fim_insercao:
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


# Percorre e imprime os valores da lista
imprimir_lista:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    
    lw s0, head_lista       # s0 é o nó atual

imprimir_loop:
    beq s0, zero, imprimir_fim
    li a7, 1
    lw a0, 0(s0)
    ecall
    
    # imprime um espaço
    li a7, 4
    la a0, msg_espaco
    ecall
    
    # próximo nó
    lw s0, 4(s0)
    j imprimir_loop

imprimir_fim:
    li a7, 4
    la a0, msg_newline
    ecall
    
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
