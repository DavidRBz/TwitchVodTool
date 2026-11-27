# 📺 Twitch VOD & Chat Tool

<details>
<summary><strong>🇧🇷 Tutorial em Português (BR) — Clique para expandir</strong></summary>

Uma ferramenta em PowerShell e Batch para Windows feita para baixar VODs da Twitch ou segmentos `.ts` ao vivo, baixar arquivos de chat, juntar arquivos `.ts` com FFmpeg e renderizar o chat sobre vídeos — com janelas do Explorador de Arquivos do Windows, progresso de `0/100%`, detecção automática de ferramentas, suspensão automática após o download e suporte completo a **English** e **Português (BR)**.

### 📦 Como Baixar e Usar

1. Acesse a aba **Releases** (à direita nesta página) e baixe o arquivo **`TwitchVodTool-v*.zip`** mais recente.
2. Extraia o `.zip` em qualquer pasta do seu PC.
3. Dê um duplo clique em **`Run_TwitchVodTool.bat`**.
4. Na primeira abertura, escolha o idioma (**`1`** para English ou **`2`** para Português BR). O script salva sua escolha em `app/config.json` e exibe tudo no idioma selecionado.

### 📁 Estrutura de Pastas

```text
TwitchVodTool/
├── Run_TwitchVodTool.bat
├── README.md
└── app/
    ├── config.json
    └── TwitchVodTool.ps1
```

### 🛠️ Ferramentas Externas Necessárias

Este projeto não inclui executáveis embutidos. Ao iniciar, o script **detecta automaticamente** se as ferramentas abaixo já estão no `PATH` ou em pastas padrão do Windows e salva os caminhos em `app/config.json`. Caso alguma esteja faltando, o próprio programa oferece um assistente para localizar pelo Explorador de Arquivos, instalar via `winget` ou abrir a página oficial de download.

Se preferir instalar antes manualmente:

1. **`TwitchDownloaderCLI`**
   - Acesse [TwitchDownloader Releases](https://github.com/lay295/TwitchDownloader/releases) e baixe o arquivo mais recente para Windows (`TwitchDownloaderCLI-*-Windows-x64.zip`).
   - Extraia o `TwitchDownloaderCLI.exe` em uma pasta de sua preferência (ou adicione ao `PATH`).

2. **`FFmpeg` (inclui `ffmpeg.exe` e `ffprobe.exe`)**
   - Pelo `winget`:
     ```powershell
     winget install -e --id Gyan.FFmpeg
     ```
   - Ou baixe uma build para Windows em [gyan.dev FFmpeg builds](https://www.gyan.dev/ffmpeg/builds/) ou [BtbN FFmpeg Builds](https://github.com/BtbN/FFmpeg-Builds/releases) e extraia (ex.: `C:\ffmpeg\bin\`).

3. **`yt-dlp`**
   - Pelo `winget`:
     ```powershell
     winget install -e --id yt-dlp.yt-dlp
     ```
   - Ou baixe o `yt-dlp.exe` em [yt-dlp Releases](https://github.com/yt-dlp/yt-dlp/releases).

### 📋 Opções do Menu

- **`0` — ⚙️ Alterar configurações:** Edita idioma, caminhos das ferramentas (com opção `B` para abrir o Explorador), pasta padrão de saída, codificador/qualidade (`auto` testa automaticamente sua GPU `nvenc` / `amf` / `qsv` e usa `cpu` se necessário), aparência do chat e comportamento ao finalizar uma tarefa.
- **`1` — 🎬 Baixar VOD / Transmissão ao vivo (Apenas vídeo):** Se informar um ID/URL de VOD, baixa via `TwitchDownloaderCLI`. Se informar um canal ao vivo, captura os segmentos `.ts` do início até a live encerrar e os mescla automaticamente com FFmpeg.
- **`2` — 💬 Baixar VOD / Transmissão ao vivo + Renderizar Chat:** Faz o mesmo que a opção `1` e, em seguida, baixa o chat (com suporte a BTTV, FFZ e 7TV), renderiza o vídeo do chat e aplica a sobreposição no vídeo final.
- **`3` — 🧩 Juntar arquivos `.ts` existentes em MP4:** Abre o Explorador de Arquivos para escolher a pasta com os `.ts` e o destino/nome do `.mp4` final (se cancelar o destino, salva em `Downloads`).
- **`4` — 🎞️ Baixar Chat e Renderizar sobre um vídeo existente:** Pede o ID/URL do VOD, abre o Explorador para escolher o vídeo local e o arquivo de saída, compara a duração do VOD com o vídeo selecionado para sincronização (com ajuste de deslocamento em segundos) e renderiza o chat sobre ele.
- **`5` — 📝 Baixar arquivo de chat:** Pede o ID/URL do VOD e abre o Explorador de Arquivos para escolher o destino e o formato (`.json`, `.txt` ou `.html`).

### 😴 Suspensão Automática (Sleep)

- Disponível nas opções **`1` a `4`** (desativada na opção `5`, pois baixar apenas o chat é quase instantâneo).
- Pressione **Enter** para não suspender, ou informe quantos minutos após o término o PC deve entrar em **Suspender**.
- Nas opções `1` e `2`, com temporizador ativo, o PC suspende automaticamente assim que o download termina, sem travar em perguntas. Ao acordar o PC, o terminal pergunta se deseja continuar com a mesclagem/renderização.

### 🔄 Comportamento ao Finalizar

- Ao concluir qualquer opção, o programa pergunta se você deseja continuar usando (`S/N`), limpando o terminal e voltando ao menu principal se confirmar.
- Na primeira vez, também é oferecida a opção de **não mostrar esta pergunta novamente** (salva em `app/config.json`): dependendo da sua escolha, pressionar **Enter** ao final de uma tarefa limpa o terminal e volta ao menu ou fecha o programa diretamente. Isso pode ser alterado a qualquer momento na opção **`0`**.

</details>

---

A Windows PowerShell & Batch utility for downloading Twitch VODs or live `.ts` segments, downloading chat logs, merging `.ts` files with FFmpeg, and burning chat overlays onto videos — with Windows Explorer dialogs, `0/100%` progress reporting, automatic tool detection, post-download auto-sleep, and full **English** / **Português (BR)** support.

## 📦 Download & Quick Start

1. Open the **Releases** section (on the right side of this page) and download the latest **`TwitchVodTool-v*.zip`**.
2. Extract the `.zip` archive anywhere on your PC.
3. Double-click **`Run_TwitchVodTool.bat`**.
4. On first launch, choose your language (**`1`** for English or **`2`** for Português BR). Your choice is saved to `app/config.json` and the entire interface immediately switches to that language.

## 📁 Folder Structure

```text
TwitchVodTool/
├── Run_TwitchVodTool.bat
├── README.md
└── app/
    ├── config.json
    └── TwitchVodTool.ps1
```

## 🛠️ Required External Tools

This repository does not bundle third-party binaries. On startup, the script **automatically detects** whether each required tool is available in your `PATH` or common Windows install locations and saves valid paths to `app/config.json`. If anything is missing, a guided prompt lets you browse for the `.exe` via Windows Explorer, install it automatically with `winget`, or open the official download page.

If you prefer to install them manually beforehand:

1. **`TwitchDownloaderCLI`**
   - Go to [TwitchDownloader Releases](https://github.com/lay295/TwitchDownloader/releases) and download the latest Windows archive (`TwitchDownloaderCLI-*-Windows-x64.zip`).
   - Extract `TwitchDownloaderCLI.exe` anywhere convenient (or add its folder to your Windows `PATH`).

2. **`FFmpeg` (includes `ffmpeg.exe` and `ffprobe.exe`)**
   - Via `winget`:
     ```powershell
     winget install -e --id Gyan.FFmpeg
     ```
   - Or download a Windows build from [gyan.dev FFmpeg builds](https://www.gyan.dev/ffmpeg/builds/) or [BtbN FFmpeg Builds](https://github.com/BtbN/FFmpeg-Builds/releases) and extract it (e.g., `C:\ffmpeg\bin\`).

3. **`yt-dlp`**
   - Via `winget`:
     ```powershell
     winget install -e --id yt-dlp.yt-dlp
     ```
   - Or download `yt-dlp.exe` from [yt-dlp Releases](https://github.com/yt-dlp/yt-dlp/releases).

## 📋 Menu Options

- **`0` — ⚙️ Change configuration:** Edit language, tool paths (type `B` to pick executables via Windows Explorer), default output folder, encoder/quality (`auto` probes your GPU for `nvenc` / `amf` / `qsv` and falls back to `cpu`), chat overlay styling, and post-task behavior in `app/config.json`.
- **`1` — 🎬 Download VOD / Live Stream (Video only):** Downloads a VOD via `TwitchDownloaderCLI` when given a VOD ID/URL. When given a live channel name/URL, captures `.ts` segments from the start until the stream ends and merges them with FFmpeg.
- **`2` — 💬 Download VOD / Live Stream + Render Chat:** Performs option `1`, then downloads chat (with BTTV, FFZ, and 7TV support), renders the chat video, and burns the overlay onto the final video.
- **`3` — 🧩 Join existing `.ts` files into MP4:** Opens Windows Explorer dialogs to choose the `.ts` folder and destination path/filename (defaults to `Downloads` if canceled).
- **`4` — 🎞️ Download Chat & Render onto an existing video file:** Prompts for a VOD ID/URL, opens Windows Explorer to select the local video and output filename, compares VOD duration against your local video for sync (with optional start offset), and burns the chat overlay onto it.
- **`5` — 📝 Download Chat file:** Prompts for a VOD ID/URL and opens Windows Explorer to choose the destination folder and format (`.json`, `.txt`, or `.html`).

## 😴 Auto-Sleep Behavior

- Available for options **`1`–`4`** (disabled for option `5`, since chat-only downloads finish almost instantly).
- Press **Enter** to skip sleep, or enter how many minutes after completion the PC should enter **Sleep**.
- In options `1` and `2`, when a sleep timer is set, the PC enters Sleep automatically once downloading completes without blocking on prompts. On wake, the terminal asks whether to continue with merging/rendering.

## 🔄 Post-Task Flow

- After any option finishes, the script asks if you want to continue using the program (`Y/N`), clearing the terminal and returning to the main menu if you continue.
- The first time this prompt appears, you can choose **Don't show this again** (saved in `app/config.json`): depending on your preference, pressing **Enter** after future tasks will either clear the terminal and restart the menu or close the program cleanly. You can change or reset this behavior anytime in option **`0`**.