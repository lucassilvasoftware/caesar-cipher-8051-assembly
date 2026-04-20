# Cifra de César em linguagem assembly

Implementação em **assembly** de um fluxo de cifragem por deslocamento (cifra de César), com interação para entrada do deslocamento e da mensagem, adequada a microcontrolador da família **8051** (registros de portas, UART, etc.), conforme o arquivo `cipher_encrypter.asm`.

## Tecnologias

- Assembly 8051 (sintaxe compatível com montadores como Keil uVision / SDCC, conforme seu ambiente)

## Como montar e executar

1. Abra `cipher_encrypter.asm` no IDE ou na toolchain que você utiliza para 8051.

2. Configure o projeto para o microcontrolador alvo (mapa de memória, frequência do cristal, se aplicável).

3. Monte (assemble), grave o HEX na placa e execute no hardware ou simulador suportado pela mesma toolchain.

Detalhes de pinos (LCD, serial, etc.) estão descritos em comentários e diretivas no próprio arquivo-fonte.
