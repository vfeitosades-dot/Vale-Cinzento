# Vale Cinzento · Travessia do Vale

Uma travessia de sobrevivência em terceira pessoa, feita na Godot 4.4.1. O jogo começa perto do Abrigo da Figueira. Na mesa há um rádio, uma garrafa e o primeiro registro sobre a antiga rota do vale. Você pode seguir esse registro a pé ou pegar a perua para visitar a mercearia, a oficina, a ponte, o reservatório e o mirante.

[Baixar para Windows x64 (.exe)](https://github.com/vfeitosades-dot/Vale-Cinzento/releases/latest/download/Vale-Cinzento-Windows-x64.exe) · [Baixar para Android ARM64 (.apk)](https://github.com/vfeitosades-dot/Vale-Cinzento/releases/latest/download/Vale-Cinzento-Android-arm64.apk) · [Todas as versões](https://github.com/vfeitosades-dot/Vale-Cinzento/releases)

![Cena do Vale Cinzento renderizada pelo jogo na Godot](https://github.com/vfeitosades-dot/Vale-Cinzento/releases/download/v0.1.0/Travessia.png)

## Como jogar

No **Windows**, abra o executável. No **Android**, abra o APK em um aparelho ARM64 e jogue com a tela na horizontal. A campanha funciona offline e fica salva no aparelho. O menu **Pausa** inclui a opção **Salvar agora**.

| Ação | Teclado e mouse | Tela de toque |
| --- | --- | --- |
| Caminhar ou conduzir | W, A, S, D ou setas | Arraste no lado esquerdo |
| Correr a pé | Segure Shift enquanto anda | Estenda o arraste do lado esquerdo |
| Girar a câmera | Arraste com o botão direito do mouse | Deslize no lado direito |
| Interagir ou entrar e sair da perua | E, perto do ponto de interação | Toque no botão dourado |
| Consultar mochila, fabricação, mapa e diário | I, C, M e J | Use as abas na parte inferior |
| Pausar ou voltar | Esc | Toque em Pausa ou use Voltar |

Na mochila, escolha um alimento para comer, use a garrafa para beber ou ligue a lanterna. Na fabricação, consulte quais materiais cada receita exige. Para começar uma horta, reúna uma ripa e terra, fabrique uma caixa de mudas, instale-a no abrigo e plante as sementes. O diário guarda as pistas para marcar a trilha e completar o boletim pelo rádio do mirante.

## Projeto Godot

Esta é a primeira versão jogável baseada no material de pré-produção **Vale Cinzento V7**. O cenário, o personagem, a perua, os sons e a interface desta edição são criados pelo próprio projeto. O vale desta prévia tem seis pontos de interesse, dez receitas, um veículo dirigível e uma campanha persistente.

Para abrir o código, importe `project.godot` na Godot 4.4.1 e execute a cena principal com F6 a partir de `Main.tscn`, ou pressione F5 em qualquer cena. Os presets de Windows e Android estão em `export_presets.cfg`. O histórico de exportações e testes está disponível no [GitHub Actions](https://github.com/vfeitosades-dot/Vale-Cinzento/actions).

A Godot Engine é distribuída sob a licença MIT. [Licença da Godot](https://godotengine.org/license/) · [Avisos sobre componentes da engine](https://github.com/godotengine/godot/blob/4.4.1-stable/COPYRIGHT.txt)
