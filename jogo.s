# ==============================================================================
# Universidade de Sao Paulo - ICMC - Departamento de Sistemas de Computacao
# SSC0902 - Organizacao e Arquitetura de Computadores
# 1o Trabalho Pratico - Jogo "Adivinhe o Numero" em Assembly RISC-V
#
# Grupo:
#   - <nome do integrante 1> - <numero USP>
#   - <nome do integrante 2> - <numero USP>
#   - <nome do integrante 3> - <numero USP>
#   - <nome do integrante 4> - <numero USP>
#
# Descricao:
#   O computador sorteia um numero entre 1 e 100 usando um Gerador Congruente
#   Linear (GCL) e o jogador tenta adivinha-lo. A cada palpite o programa
#   informa se o numero secreto e maior ("muito baixo") ou menor ("muito alto").
#   Todos os palpites sao armazenados em uma lista ligada alocada
#   DINAMICAMENTE NA HEAP (syscall sbrk), nunca na pilha. Ao final, a lista e
#   percorrida do inicio ao fim para exibir o historico de tentativas.
#
# Simulador alvo: RARS (RISC-V Assembler and Runtime Simulator)
# ==============================================================================

# ------------------------------------------------------------------------------
# Constantes simbolicas
# ------------------------------------------------------------------------------
# Codigos das chamadas de sistema (ecall) do RARS
.eqv SYS_PRINT_INT    1         # a0 = inteiro a ser impresso
.eqv SYS_PRINT_STR    4         # a0 = endereco da string terminada em '\0'
.eqv SYS_READ_INT     5         # retorna em a0 o inteiro lido do teclado
.eqv SYS_SBRK         9         # a0 = bytes pedidos; retorna endereco na heap
.eqv SYS_EXIT        10         # encerra o programa
.eqv SYS_TIME        30         # a0 = tempo do sistema (ms), parte baixa

# Parametros do Gerador Congruente Linear: X(n+1) = (a * X(n) + c) mod m
# Valores classicos do glibc, com m = 2^31.
.eqv LCG_A   1103515245
.eqv LCG_C   12345
.eqv LCG_MASCARA 0x7FFFFFFF     # equivale ao "mod 2^31"

# Estrutura do no da lista ligada (8 bytes):
#   offset 0 -> valor do palpite (word)
#   offset 4 -> ponteiro para o proximo no (word), 0 indica fim da lista
.eqv NO_TAMANHO    8
.eqv NO_OFF_VALOR  0
.eqv NO_OFF_PROX   4

# Intervalo do sorteio
.eqv LIMITE_INFERIOR    1
.eqv LIMITE_SUPERIOR  100
.eqv FAIXA            100       # LIMITE_SUPERIOR - LIMITE_INFERIOR + 1

# ------------------------------------------------------------------------------
# Segmento de dados
# ------------------------------------------------------------------------------
.data

msg_titulo:
    .string "\n========================================\n   JOGO: ADIVINHE O NUMERO\n========================================\n"
msg_regras:
    .string "Eu escolhi um numero inteiro entre 1 e 100.\nTente adivinhar! A cada palpite eu digo se ele\nesta muito alto ou muito baixo.\n\n"
msg_palpite:
    .string "Digite seu palpite (1 a 100): "
msg_invalido:
    .string ">> Palpite invalido! O numero deve estar entre 1 e 100.\n"
msg_alto:
    .string ">> Muito alto!\n\n"
msg_baixo:
    .string ">> Muito baixo!\n\n"
msg_correto:
    .string "\n>> PARABENS! Voce acertou o numero "
msg_tentativas:
    .string "Total de tentativas: "
msg_historico:
    .string "\nHistorico de palpites (lista ligada na heap):\n"
msg_tentativa_n:
    .string "  Tentativa "
msg_separador:
    .string ": "
msg_fim:
    .string "\nObrigado por jogar!\n"
msg_erro_heap:
    .string "\n>> ERRO: falha ao alocar memoria na heap.\n"
msg_nova_linha:
    .string "\n"

semente:        .word 0         # estado atual do gerador congruente linear
lista_inicio:   .word 0         # ponteiro para o primeiro no da lista ligada
lista_fim:      .word 0         # ponteiro para o ultimo no (insercao em O(1))

# ------------------------------------------------------------------------------
# Segmento de codigo
# ------------------------------------------------------------------------------
.text
.globl main

# ==============================================================================
# main - fluxo principal do jogo
#   s0 = numero secreto sorteado
#   s1 = palpite atual do jogador
#   s2 = contador de tentativas
# ==============================================================================
main:
    addi sp, sp, -16                # prologo: reserva espaco na pilha
    sw   ra, 12(sp)
    sw   s0,  8(sp)
    sw   s1,  4(sp)
    sw   s2,  0(sp)

    jal  ra, imprime_abertura       # mensagem de boas-vindas e instrucoes
    jal  ra, inicializa_semente     # semente do GCL a partir do relogio
    jal  ra, sorteia_numero         # sorteia o numero secreto
    mv   s0, a0

    li   s2, 0                      # contador de tentativas = 0

main_laco:
    jal  ra, le_palpite             # le e valida o palpite do jogador
    mv   s1, a0

    mv   a0, s1
    jal  ra, lista_insere           # guarda o palpite na lista ligada (heap)

    addi s2, s2, 1                  # uma tentativa a mais

    blt  s1, s0, main_muito_baixo   # palpite < secreto  -> muito baixo
    bgt  s1, s0, main_muito_alto    # palpite > secreto  -> muito alto
    j    main_acertou

main_muito_baixo:
    la   a0, msg_baixo
    li   a7, SYS_PRINT_STR
    ecall
    j    main_laco

main_muito_alto:
    la   a0, msg_alto
    li   a7, SYS_PRINT_STR
    ecall
    j    main_laco

main_acertou:
    la   a0, msg_correto            # "PARABENS! Voce acertou o numero "
    li   a7, SYS_PRINT_STR
    ecall
    mv   a0, s0
    li   a7, SYS_PRINT_INT
    ecall
    la   a0, msg_nova_linha
    li   a7, SYS_PRINT_STR
    ecall

    la   a0, msg_tentativas         # "Total de tentativas: "
    li   a7, SYS_PRINT_STR
    ecall
    mv   a0, s2
    li   a7, SYS_PRINT_INT
    ecall
    la   a0, msg_nova_linha
    li   a7, SYS_PRINT_STR
    ecall

    jal  ra, lista_imprime          # percorre a lista ligada ate o fim

    la   a0, msg_fim
    li   a7, SYS_PRINT_STR
    ecall

    lw   s2,  0(sp)                 # epilogo: restaura os registradores
    lw   s1,  4(sp)
    lw   s0,  8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16

    li   a7, SYS_EXIT               # encerra o programa
    ecall

# ==============================================================================
# imprime_abertura - exibe o titulo e as regras do jogo
#   Entrada: nenhuma          Saida: nenhuma
# ==============================================================================
imprime_abertura:
    la   a0, msg_titulo
    li   a7, SYS_PRINT_STR
    ecall
    la   a0, msg_regras
    li   a7, SYS_PRINT_STR
    ecall
    jr   ra

# ==============================================================================
# inicializa_semente - define a semente do GCL usando o relogio do sistema,
#                      garantindo uma partida diferente a cada execucao.
#   Entrada: nenhuma          Saida: nenhuma (escreve em 'semente')
# ==============================================================================
inicializa_semente:
    li   a7, SYS_TIME               # a0 = parte baixa do tempo em ms
    ecall
    li   t0, LCG_MASCARA
    and  t1, a0, t0                 # mantem a semente em [0, 2^31 - 1]
    bnez t1, inicializa_semente_grava
    li   t1, 1                      # evita a semente degenerada 0
inicializa_semente_grava:
    la   t0, semente
    sw   t1, 0(t0)
    jr   ra

# ==============================================================================
# gcl_proximo - Gerador Congruente Linear: X(n+1) = (a * X(n) + c) mod 2^31
#   Entrada: nenhuma          Saida: a0 = proximo valor pseudoaleatorio
#   Funcao folha: nao chama ninguem, logo nao usa a pilha.
# ==============================================================================
gcl_proximo:
    la   t0, semente
    lw   t1, 0(t0)                  # X(n)
    li   t2, LCG_A
    mul  t1, t1, t2                 # a * X(n)
    li   t2, LCG_C
    add  t1, t1, t2                 # a * X(n) + c
    li   t2, LCG_MASCARA
    and  t1, t1, t2                 # mod 2^31
    sw   t1, 0(t0)                  # atualiza o estado do gerador
    mv   a0, t1
    jr   ra

# ==============================================================================
# sorteia_numero - devolve um inteiro pseudoaleatorio no intervalo [1, 100]
#   Entrada: nenhuma          Saida: a0 = numero sorteado
#   Os bits mais significativos do GCL sao usados porque os bits baixos de um
#   gerador congruente linear tem periodo curto.
# ==============================================================================
sorteia_numero:
    addi sp, sp, -4
    sw   ra, 0(sp)

    jal  ra, gcl_proximo
    srli t0, a0, 16                 # descarta os 16 bits menos significativos
    li   t1, FAIXA
    remu t2, t0, t1                 # resto em [0, 99]
    addi a0, t2, LIMITE_INFERIOR    # desloca para [1, 100]

    lw   ra, 0(sp)
    addi sp, sp, 4
    jr   ra

# ==============================================================================
# le_palpite - solicita e valida um palpite do jogador
#   Entrada: nenhuma          Saida: a0 = palpite valido em [1, 100]
# ==============================================================================
le_palpite:
    la   a0, msg_palpite
    li   a7, SYS_PRINT_STR
    ecall

    li   a7, SYS_READ_INT
    ecall
    mv   t0, a0                     # t0 = valor lido

    li   t1, LIMITE_INFERIOR
    blt  t0, t1, le_palpite_invalido
    li   t1, LIMITE_SUPERIOR
    bgt  t0, t1, le_palpite_invalido

    mv   a0, t0                     # palpite valido
    jr   ra

le_palpite_invalido:
    la   a0, msg_invalido
    li   a7, SYS_PRINT_STR
    ecall
    j    le_palpite                 # pede novamente

# ==============================================================================
# lista_insere - cria um no na HEAP e o insere no final da lista ligada
#   Entrada: a0 = valor do palpite        Saida: nenhuma
#   A memoria do no vem exclusivamente da syscall sbrk (heap); a pilha e usada
#   apenas para salvar registradores, conforme a convencao de chamada.
#   s0 = valor recebido, s1 = endereco do novo no
# ==============================================================================
lista_insere:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    mv   s0, a0                     # preserva o valor antes da ecall

    li   a0, NO_TAMANHO             # aloca 8 bytes na heap
    li   a7, SYS_SBRK
    ecall
    beqz a0, lista_insere_erro      # sbrk retorna 0 se nao houver memoria
    mv   s1, a0                     # s1 = endereco do novo no

    sw   s0, NO_OFF_VALOR(s1)       # no->valor = palpite
    sw   zero, NO_OFF_PROX(s1)      # no->prox  = NULL

    la   t0, lista_inicio
    lw   t1, 0(t0)
    bnez t1, lista_insere_no_fim

    sw   s1, 0(t0)                  # lista vazia: o novo no vira o inicio
    la   t0, lista_fim
    sw   s1, 0(t0)
    j    lista_insere_retorno

lista_insere_no_fim:
    la   t0, lista_fim
    lw   t2, 0(t0)                  # t2 = ultimo no atual
    sw   s1, NO_OFF_PROX(t2)        # ultimo->prox = novo no
    sw   s1, 0(t0)                  # lista_fim = novo no

lista_insere_retorno:
    lw   s1, 0(sp)
    lw   s0, 4(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    jr   ra

lista_insere_erro:
    la   a0, msg_erro_heap
    li   a7, SYS_PRINT_STR
    ecall
    li   a7, SYS_EXIT
    ecall

# ==============================================================================
# lista_imprime - percorre a lista ligada do inicio ate o fim (prox == NULL)
#                 imprimindo todos os palpites armazenados
#   Entrada: nenhuma          Saida: nenhuma
#   s0 = no atual, s1 = indice da tentativa
# ==============================================================================
lista_imprime:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    la   a0, msg_historico
    li   a7, SYS_PRINT_STR
    ecall

    la   t0, lista_inicio
    lw   s0, 0(t0)                  # s0 = primeiro no
    li   s1, 1                      # numero da tentativa

lista_imprime_laco:
    beqz s0, lista_imprime_fim      # chegou ao fim da lista

    la   a0, msg_tentativa_n        # "  Tentativa "
    li   a7, SYS_PRINT_STR
    ecall
    mv   a0, s1
    li   a7, SYS_PRINT_INT
    ecall
    la   a0, msg_separador          # ": "
    li   a7, SYS_PRINT_STR
    ecall
    lw   a0, NO_OFF_VALOR(s0)       # valor guardado no no
    li   a7, SYS_PRINT_INT
    ecall
    la   a0, msg_nova_linha
    li   a7, SYS_PRINT_STR
    ecall

    lw   s0, NO_OFF_PROX(s0)        # avanca para o proximo no
    addi s1, s1, 1
    j    lista_imprime_laco

lista_imprime_fim:
    lw   s1, 0(sp)
    lw   s0, 4(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    jr   ra
