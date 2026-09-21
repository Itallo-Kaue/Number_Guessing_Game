# Adivinhe o Número — Assembly RISC-V

**SSC0902 – Organização e Arquitetura de Computadores — 1º Trabalho Prático**

Implementação do jogo "Adivinhe o Número" em Assembly RISC-V (RV32IM), com número
secreto gerado por um **Gerador Congruente Linear (GCL)** e histórico de palpites
armazenado em uma **lista ligada alocada dinamicamente na heap** (syscall `sbrk`).

## Arquivos

| Arquivo | Descrição |
|---|---|
| `jogo.s` | Código-fonte completo do jogo em Assembly RISC-V |
| `relatorio.docx` | Relatório de desenvolvimento |
| `README.md` | Este arquivo (instruções de execução) |

## Como executar (RARS)

1. Baixe o simulador **RARS** (arquivo `rars1_6.jar`) em
   <https://github.com/TheThirdOne/rars/releases>. É necessário ter o **Java 8 ou superior**
   instalado.

2. **Modo gráfico (recomendado):**
   ```bash
   java -jar rars1_6.jar
   ```
   - `File → Open…` e selecione `jogo.s`
   - Clique em **Assemble** (F3)
   - Clique em **Run** (F5)
   - Digite os palpites na aba **Run I/O**, na parte inferior da janela

3. **Modo linha de comando:**
   ```bash
   java -jar rars1_6.jar nc jogo.s
   ```
   Os palpites são digitados diretamente no terminal.

> **Observação:** o programa usa as instruções `mul` e `remu`, da extensão **M**,
> habilitada por padrão no RARS. Nenhuma configuração adicional é necessária.

## Como jogar

O programa sorteia um inteiro entre 1 e 100. A cada palpite digitado ele responde:

- `>> Muito baixo!` — o número secreto é maior que o palpite
- `>> Muito alto!` — o número secreto é menor que o palpite
- `>> PARABENS!` — acertou

Palpites fora do intervalo [1, 100] são rejeitados e solicitados novamente.
Ao acertar, o programa exibe o número de tentativas e percorre a lista ligada
imprimindo todos os palpites na ordem em que foram feitos.

## Exemplo de execução

```
========================================
   JOGO: ADIVINHE O NUMERO
========================================
Eu escolhi um numero inteiro entre 1 e 100.
Tente adivinhar! A cada palpite eu digo se ele
esta muito alto ou muito baixo.

Digite seu palpite (1 a 100): 50
>> Muito alto!

Digite seu palpite (1 a 100): 25
>> Muito baixo!

Digite seu palpite (1 a 100): 37
>> Muito baixo!

Digite seu palpite (1 a 100): 43
>> PARABENS! Voce acertou o numero 43
Total de tentativas: 4

Historico de palpites (lista ligada na heap):
  Tentativa 1: 50
  Tentativa 2: 25
  Tentativa 3: 37
  Tentativa 4: 43

Obrigado por jogar!
```

## Estrutura do código

| Rótulo | Papel |
|---|---|
| `main` | Fluxo principal: sorteio, laço de palpites e finalização |
| `imprime_abertura` | Mensagem de boas-vindas e instruções |
| `inicializa_semente` | Define a semente do GCL a partir do relógio do sistema (`ecall` 30) |
| `gcl_proximo` | Gerador Congruente Linear: `X(n+1) = (1103515245·X(n) + 12345) mod 2^31` |
| `sorteia_numero` | Converte o valor do GCL para o intervalo [1, 100] |
| `le_palpite` | Lê e valida o palpite do jogador |
| `lista_insere` | Aloca um nó de 8 bytes com `sbrk` e o insere no fim da lista |
| `lista_imprime` | Percorre a lista até `prox == NULL` imprimindo os palpites |

Cada nó da lista ligada ocupa 8 bytes na heap: um *word* com o valor do palpite
(offset 0) e um *word* com o endereço do próximo nó (offset 4, sendo `0` = fim da lista).

## Chamadas de sistema utilizadas (RARS)

| `a7` | Serviço |
|---|---|
| 1 | `print_int` |
| 4 | `print_string` |
| 5 | `read_int` |
| 9 | `sbrk` (alocação na heap) |
| 10 | `exit` |
| 30 | `time` (semente do gerador) |

## Integrantes do grupo

- `<nome do integrante 1>` — `<nº USP>`
- `<nome do integrante 2>` — `<nº USP>`
- `<nome do integrante 3>` — `<nº USP>`
- `<nome do integrante 4>` — `<nº USP>`
