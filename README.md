# Adivinhe o Número — Assembly RISC-V

**SSC0902 – Organização e Arquitetura de Computadores — 1º Trabalho Prático**
Docente: Sarita Mazzini Bruschi

Jogo "Adivinhe o Número" implementado em Assembly RISC-V. O computador sorteia um
número entre 1 e 100 usando um **Gerador Congruente Linear (GCL)** e o jogador tenta
descobri-lo; a cada palpite o programa informa se ele está acima ou abaixo do número
secreto. Todos os palpites são armazenados em uma **lista ligada alocada
dinamicamente na heap** (syscall `sbrk`) e impressos ao final da partida.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `adivinhenumero.asm` | Código-fonte do jogo em Assembly RISC-V |
| `README.md` | Este arquivo (instruções de execução) |

## Requisitos

- **Java 8 ou superior**. Para conferir, abra o terminal (Prompt de Comando no Windows)
  e execute `java -version`. Se não estiver instalado, baixe em <https://adoptium.net>.
- **RARS** — *RISC-V Assembler and Runtime Simulator*. Baixe o arquivo `rars1_6.jar`
  na página de releases: <https://github.com/TheThirdOne/rars/releases>. Não há
  instalação: é um único `.jar` que já vem pronto para executar.

O programa usa as instruções `mul` e `rem`, da extensão **M** da arquitetura,
habilitada por padrão no RARS. Nenhuma configuração adicional é necessária.

## Como executar — passo a passo (interface gráfica)

**1. Abrir o simulador.**
Dê um duplo clique em `rars1_6.jar`. Se o duplo clique não funcionar, abra o terminal
na pasta onde o arquivo está e execute:

```bash
java -jar rars1_6.jar
```

**2. Carregar o código.**
No menu `File → Open…`, selecione o arquivo `adivinhenumero.asm`. O código aparece na
aba *Edit*.

**3. Montar o programa.**
Clique em **Assemble** (o ícone da chave de boca na barra de ferramentas, ou a tecla
**F3**). A aba *Execute* é aberta mostrando o código traduzido. Se aparecer alguma
mensagem em vermelho na parte de baixo, o arquivo não foi montado — confira se
selecionou o arquivo certo.

**4. Executar.**
Clique em **Run** (o ícone ▶, ou a tecla **F5**). A partir daqui toda a interação
acontece na aba **Run I/O**, no rodapé da janela.

**5. Informar a semente.**
O programa pede um número inteiro para a semente do gerador. Clique na caixa de texto
da aba *Run I/O*, digite um número qualquer e pressione **Enter**. Sementes diferentes
geram números secretos diferentes (a semente `7`, por exemplo, gera o número 65).

**6. Jogar.**
Digite cada palpite, entre 1 e 100, no mesmo campo, sempre seguido de **Enter**. O
programa responde:

- `Seu palpite eh maior` — o número secreto é menor que o seu palpite
- `Seu palpite eh menor` — o número secreto é maior que o seu palpite
- `Correto! Voce acertou!` — fim de jogo

Valores fora do intervalo de 1 a 100 são recusados com `Palpite fora da faixa!` e não
contam como tentativa.

**7. Ver o resultado.**
Ao acertar, o programa exibe o total de tentativas e a lista completa de palpites, na
ordem em que foram feitos, percorrendo a lista ligada da heap.

**8. Jogar novamente.**
Clique em **Reset** (tecla **F12**) e depois em **Run** outra vez.

> **Dica:** para acompanhar a execução instrução por instrução, use **Step** (F7) em
> vez de *Run*. Na aba *Data Segment*, selecionando a região da *heap*, dá para ver os
> nós da lista ligada sendo criados a cada palpite.

## Como executar — linha de comando

```bash
java -jar rars1_6.jar nc adivinhenumero.asm
```

A opção `nc` omite a mensagem de copyright. A semente e os palpites são digitados
diretamente no terminal.

## Exemplo de execução

```
Bem-vindo ao jogo Adivinhe o Numero!
O computador escolheu um numero entre 1 e 100.
Digite um numero inteiro para a semente (RNG): 7

Digite seu palpite: 150
Palpite fora da faixa! Digite um numero entre 1 a 100

Digite seu palpite: 100
Seu palpite eh maior

Digite seu palpite: 50
Seu palpite eh menor

Digite seu palpite: 70
Seu palpite eh maior

Digite seu palpite: 65
Correto! Voce acertou!
Total de tentativas: 4
Seus palpites foram: 100 50 70 65
```

*(saída real do RARS; repare que o palpite inválido não entrou na contagem nem na lista)*

## Estrutura do código

| Rótulo | Responsabilidade |
|---|---|
| `main` | Fluxo principal: abertura, sorteio, laço de palpites e finalização |
| `jogo_loop` | Laço que lê o palpite, conta a tentativa, insere na lista e dá a dica |
| `ler_semente` | Lê do teclado o valor inicial da semente do gerador |
| `gerar_numero` | GCL: `X(n+1) = (1103515245·X(n) + 12345) mod 2³¹`, reduzido a [1, 100] a partir dos bits mais significativos |
| `ler_palpite` | Exibe o prompt, lê o palpite e valida o intervalo [1, 100] |
| `palpite_invalido` | Avisa o jogador e repete o pedido, sem contar tentativa |
| `verificar_palpite` | Compara o palpite com o número secreto; retorna 1 no acerto e 0 caso contrário |
| `novo_no` | Aloca 8 bytes na heap (`sbrk`) e inicializa o nó |
| `erro_heap` | Encerra o programa caso a alocação falhe |
| `inserir_lista` | Insere o nó no fim da lista, mantendo `head_lista` e `tail_lista` |
| `imprimir_lista` | Percorre a lista do início até `next == 0`, imprimindo os palpites |

Cada nó da lista ocupa **8 bytes na heap**: um *word* com o valor do palpite
(deslocamento 0) e um *word* com o endereço do próximo nó (deslocamento 4, sendo `0`
o fim da lista). Manter também o ponteiro `tail_lista` permite inserir no fim em tempo
constante, preservando a ordem cronológica dos palpites.

## Chamadas de sistema utilizadas (RARS)

| `a7` | Serviço | Uso no programa |
|---|---|---|
| 1 | `print_int` | Contador de tentativas e valores da lista |
| 4 | `print_string` | Todas as mensagens de texto |
| 5 | `read_int` | Leitura da semente e dos palpites |
| 9 | `sbrk` | Alocação de cada nó da lista ligada na heap |
| 10 | `exit` | Encerramento do programa |

## Observações

- O programa espera **números inteiros** nas duas entradas. Digitar letras ou deixar o
  campo em branco faz o RARS interromper a execução com erro de leitura.
- A semente é escolhida pelo jogador: a mesma semente sempre produz o mesmo número
  secreto, o que é útil para repetir uma partida durante os testes.

## Integrantes do grupo

- Adryen Mendes da Silva — 16830145
- Ítallo Kauê Barbosa Santos — 16839029
- Natália Yumi Watanabe — 13725566
