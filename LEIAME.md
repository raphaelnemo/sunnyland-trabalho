# SunnyLand – 5 fases com chaves

Abra no **Godot 4.7** e rode `principal.tscn` (cena principal). Jogar → seletor de fases.

## Controles
- **A/D** ou setas: andar · **Espaço**: pular (segure para pular mais alto)
- **W/S**: subir/descer escada · **W** na porta: entrar · **S** em plataforma: descer
- **ESC**: pausa (continuar / reiniciar / seletor)

## Fases
| # | Cenário | Chaves | Inimigo principal | Novidades |
|---|---------|--------|-------------------|-----------|
| 1 | Floresta Ensolarada | 1 | Gambá lento (1 vida) | buracos pequenos |
| 2 | Pântano ao Entardecer | 2 | Sapo saltador | água, plataformas móveis, troncos |
| 3 | Caverna Sombria | 3 | Morcego | escuro com tochas, escadas, espinhos, inimigos com 2 vidas |
| 4 | Ruínas Celestes | 3 | Águia que mergulha | ilhas no céu, plataformas que caem/sobem |
| 5 | Fortaleza Vulcânica | 4 | **Chefe: Gambá Gigante** | lava, todos os inimigos no máximo; o chefe solta a última chave |

A porta de saída fica **trancada** até pegar todas as chaves. Passando pela porta,
a próxima fase é liberada no seletor (o progresso é salvo). Cada fase tem um checkpoint.

## Onde mexer
- `scripts/niveis.gd` – mapas (em texto) e força dos inimigos de cada fase.
- `scripts/construtor_fase.gd` – monta a fase a partir do mapa; tem a legenda dos caracteres e os temas.
- `scripts/hud_fase.gd` – chaves, mensagens, barra do chefe, pausa e fim de fase.
- `scripts/objetos/` – chave, porta trancada, checkpoint, espinho, plataforma que cai, chefe.
- `scripts/controladorFases.gd` – carrega fases, salva progresso, chaves/checkpoint, música.
- `tools/` – testes automáticos (não fazem parte do jogo).
