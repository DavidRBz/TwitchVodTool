# Ensure STA apartment state for Windows Forms dialogs
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne [System.Threading.ApartmentState]::STA) {
    $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
    & $psExe -STA -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -MemberDefinition @'
[DllImport("powrprof.dll", SetLastError = true)]
public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
'@ -Name "PowerSuspend" -Namespace "Win32"

$APP_DIR       = Split-Path -Parent $PSCommandPath
$CONFIG_PATH   = Join-Path $APP_DIR "config.json"
$DOWNLOADS_DIR = Join-Path $env:USERPROFILE "Downloads"

# ==========================================
# EXTERNAL TOOL DEFINITIONS
# ==========================================
$TOOL_SPECS = [ordered]@{
    "CLI" = @{
        DisplayName = "TwitchDownloaderCLI"
        ConfigProp  = "TwitchDownloaderCLI"
        ExeName     = "TwitchDownloaderCLI.exe"
        WingetId    = $null
        DownloadUrl = "https://github.com/lay295/TwitchDownloader/releases/latest"
    }
    "FFmpeg" = @{
        DisplayName = "FFmpeg"
        ConfigProp  = "FFmpeg"
        ExeName     = "ffmpeg.exe"
        WingetId    = "Gyan.FFmpeg"
        DownloadUrl = "https://www.gyan.dev/ffmpeg/builds/"
    }
    "FFprobe" = @{
        DisplayName = "FFprobe"
        ConfigProp  = "FFprobe"
        ExeName     = "ffprobe.exe"
        WingetId    = "Gyan.FFmpeg"
        DownloadUrl = "https://www.gyan.dev/ffmpeg/builds/"
    }
    "YtDlp" = @{
        DisplayName = "yt-dlp"
        ConfigProp  = "YtDlp"
        ExeName     = "yt-dlp.exe"
        WingetId    = "yt-dlp.yt-dlp"
        DownloadUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest"
    }
}

# ==========================================
# LOCALIZATION STRINGS (EN / PT-BR)
# ==========================================
$I18N = @{
    "en" = @{
        Title                    = "Twitch VOD & Chat Downloader / Merger"
        Opt0                     = "0. Change configuration (language, tool paths, encoding, chat)"
        Opt1                     = "1. Download VOD / Live Stream (Video only)"
        Opt2                     = "2. Download VOD / Live Stream + Render Chat"
        Opt3                     = "3. Join existing .ts files into MP4"
        Opt4                     = "4. Download Chat & Render onto an existing video file"
        Opt5                     = "5. Download Chat file from VOD ID/URL"
        SelectOption             = "Select an option (0-5)"
        SleepPrompt              = "Minutes after download/process finishes to put PC to SLEEP (press Enter for no sleep)"
        SleepScheduled           = "PC will enter SLEEP {0} minute(s) after completion."
        InvalidSleep             = "Invalid minute value '{0}'. Skipping auto-sleep."
        InvalidChoice            = "Invalid selection."
        InvalidYesNo             = "Please enter Y or N."
        ContinuePrompt           = "Do you want to continue using the program? (Y/N)"
        AskEveryTimePrompt       = "Show this prompt every time? (Y = Show every time / N = Don't show again)"
        PressEnterRestart        = "Press Enter to clear the terminal and return to the menu"
        PressEnterClose          = "Press Enter to close the program"
        ConfigSaved              = "Configuration saved to: {0}"
        SelectLang               = "Select language [1] English or [2] Portugues (BR)"
        EnterCliPath             = "TwitchDownloaderCLI.exe path (current: {0}) [Enter=keep, B=browse]"
        EnterFfmpegPath          = "ffmpeg.exe path (current: {0}) [Enter=keep, B=browse]"
        EnterFfprobePath         = "ffprobe.exe path (current: {0}) [Enter=keep, B=browse]"
        EnterYtdlpPath           = "yt-dlp.exe path (current: {0}) [Enter=keep, B=browse]"
        EnterDestDir             = "Default output folder (current: {0}, blank = Downloads)"
        EnterEncoder             = "Video encoder [auto / cpu / nvenc / amf / qsv] (current: {0})"
        EnterCrf                 = "Quality/CRF value (current: {0})"
        EnterChatWidth           = "Chat width in px (current: {0})"
        EnterChatHeight          = "Chat height in px (current: {0})"
        EnterFontSize            = "Chat font size (current: {0})"
        EnterTimestamps          = "Show timestamps? true/false (current: {0})"
        EnterMarginLeft          = "Overlay left margin in px (current: {0})"
        EnterMarginTop           = "Overlay top margin in px (current: {0})"
        EnterBgOpacity           = "Overlay background opacity 0.0-1.0 (current: {0})"
        EnterAfterTaskMode       = "After task finishes [ask / continue / exit / reset] (current: {0})"
        CheckingTools            = "Checking external tools..."
        ToolAutoDetected         = "Auto-detected {0}: {1}"
        MissingToolsHeader       = "The following required external tools were not found on this PC:"
        ConfigureToolPrompt      = "Configure {0} ({1}):"
        ToolOptBrowse            = "  [1] Locate {0} using Windows Explorer"
        ToolOptWinget            = "  [2] Install automatically via winget ({0})"
        ToolOptDownload          = "  [2] Open official download page in browser, then locate {0}"
        ToolOptManual            = "  [3] Type the full path manually"
        ToolOptSkip              = "  [4] Skip for now"
        ChooseToolAction         = "Select an option (1-4)"
        SelectExeDialog          = "Select {0}"
        TypeExePath              = "Enter the full path to {0}"
        FileNotFoundWarn         = "File not found: {0}"
        InstallingWinget         = "Installing {0} via winget..."
        WingetFailed             = "winget installation failed or was canceled (exit code {0})."
        WingetInstalledNotFound  = "winget finished, but {0} was not detected automatically. Please locate it manually."
        OpeningDownloadPage      = "Opening {0} in your browser. Download/extract it, then press Enter to select {1}..."
        ToolConfigured           = "{0} configured: {1}"
        ToolSkipped              = "Skipped {0}. Options that require it will ask to configure it before running."
        MissingRequiredAbort     = "Cannot continue: required tool '{0}' is not configured."
        EnterTarget              = "Enter Twitch VOD ID/URL or Channel Name/URL"
        EnterVodOnly             = "Enter Twitch VOD ID or URL"
        ParseError               = "Could not parse input."
        InvalidVod               = "Invalid VOD ID or URL."
        CheckingLive             = "Checking if '{0}' is currently live..."
        NotLiveFallback          = "'{0}' is not currently streaming live. Enter a VOD ID/URL (or press Enter to exit)"
        ResolvingVod             = "Resolving latest archive VOD ID for {0}..."
        NoVodYet                 = "No archive VOD found yet, retrying in 30s..."
        FoundVod                 = "Found VOD ID: {0}"
        WaitingM3u8              = "Waiting for playlist URL, retrying in 15s..."
        DownloadingTs            = "Downloading .ts segments..."
        SavedChunk               = "Saved chunk {0}.ts"
        WaitingChunk             = "Waiting for chunk {0} (HTTP {1}); still live. Sleeping 60s..."
        StreamOffline            = "Stream is offline. All .ts chunks downloaded."
        DownloadingVod           = "Downloading VOD {0}..."
        DownloadVodErr           = "Failed to download VOD {0}."
        VideoReady               = "Video saved to: {0}"
        DownloadingChat          = "Downloading chat for VOD {0}..."
        DownloadChatErr          = "Failed to download chat for VOD {0}."
        ChatSaved                = "Chat file saved to: {0}"
        RenderingChat            = "Rendering chat video..."
        RenderChatErr            = "Failed to render chat video."
        BurningOverlay           = "Burning chat overlay onto video..."
        BurnOverlayErr           = "FFmpeg overlay merge failed."
        MergedWithChat           = "Saved merged video with chat to: {0}"
        SelectTsFolder           = "Select the folder containing the .ts files..."
        NoTsFolder               = "No source folder selected."
        FolderNotFound           = "Folder not found: {0}"
        NoTsFiles                = "No .ts files found in {0}"
        BuildingPlaylist         = "Building playlist for {0} .ts files..."
        MergingTs                = "Merging .ts segments into {0}..."
        MergeTsErr               = "FFmpeg failed to join .ts files."
        JoinedSaved              = "Joined video saved to: {0}"
        SelectVideoFile          = "Select the existing video file..."
        NoVideoFile              = "No valid video file selected."
        SelectSaveDest           = "Choose destination folder and file name in the Explorer window..."
        SelectDestFolder         = "Select destination folder (Cancel to use default)..."
        VodLengthInfo            = "VOD total length:  {0} ({1:N2}s)"
        VideoLengthInfo          = "Selected video:    {0} ({1:N2}s)"
        DiffLengthInfo           = "Difference (VOD - Video): {0:N2}s ({1})"
        LengthWarn               = "Selected video length differs from the VOD by {0:N2}s."
        OffsetPrompt             = "Enter video start offset in seconds relative to VOD start (press Enter for 0)"
        ChatRangeInfo            = "Syncing chat range: {0}s -> {1}s"
        DurationCompare          = "Video duration: {0:N2}s | Chat render duration: {1:N2}s (diff: {2:N2}s)"
        DurationLockWarn         = "Duration mismatch of {0:N2}s detected. Locking output to video duration ({1:N2}s)."
        SleepCountdown           = "Task complete. Putting PC to SLEEP in {0} minute(s) ({1}s). Press Ctrl+C to cancel."
        SleepTick                = "{0} - Sleeping in ~{1} min ({2}s remaining)..."
        SleepingNow              = "{0} - Putting PC to SLEEP now..."
        WokeUpPrompt             = "PC woke up. Continue with {0}? (Y/N)"
        StoppedAfterSleep        = "Stopped before continuing. Downloaded files remain in '{0}'."
        CleanupPrompt            = "Delete intermediate files (.ts chunks, chat files, unrendered VOD)? (Y/N)"
        CleanupDone              = "Cleanup complete."
        DeleteTsPrompt           = "Delete original .ts files and filelist.txt in '{0}'? (Y/N)"
        DeleteChatTemp           = "Delete intermediate chat files (json/mp4)? (Y/N)"
        ActConfig                = "Configuration"
        ActLiveTs                = "Live .ts Capture"
        ActVodFlow               = "VOD / Stream Workflow"
        ActJoinTs                = "Join .ts Files"
        ActChatExisting          = "Chat on Existing Video"
        ActChatOnly              = "Chat Download"
        ActChatPipeline          = "Chat & Overlay Pipeline"
    }
    "pt-BR" = @{
        Title                    = "Baixador e Mesclador de VOD e Chat da Twitch"
        Opt0                     = "0. Alterar configuracoes (idioma, caminhos, codificacao, chat)"
        Opt1                     = "1. Baixar VOD / Transmissao ao vivo (Apenas video)"
        Opt2                     = "2. Baixar VOD / Transmissao ao vivo + Renderizar Chat"
        Opt3                     = "3. Juntar arquivos .ts existentes em MP4"
        Opt4                     = "4. Baixar Chat e Renderizar sobre um arquivo de video existente"
        Opt5                     = "5. Baixar arquivo de chat a partir de ID/URL de VOD"
        SelectOption             = "Escolha uma opcao (0-5)"
        SleepPrompt              = "Minutos apos o download/processo terminar para SUSPENDER o PC (Enter para nao suspender)"
        SleepScheduled           = "O PC entrara em SUSPENDER {0} minuto(s) apos a conclusao."
        InvalidSleep             = "Valor de minutos invalido '{0}'. Suspensao automatica ignorada."
        InvalidChoice            = "Opcao invalida."
        InvalidYesNo             = "Por favor, digite S ou N."
        ContinuePrompt           = "Deseja continuar usando o programa? (S/N)"
        AskEveryTimePrompt       = "Mostrar esta pergunta sempre? (S = Mostrar sempre / N = Nao mostrar novamente)"
        PressEnterRestart        = "Pressione Enter para limpar o terminal e voltar ao menu"
        PressEnterClose          = "Pressione Enter para fechar o programa"
        ConfigSaved              = "Configuracao salva em: {0}"
        SelectLang               = "Selecione o idioma [1] English ou [2] Portugues (BR)"
        EnterCliPath             = "Caminho do TwitchDownloaderCLI.exe (atual: {0}) [Enter=manter, B=procurar]"
        EnterFfmpegPath          = "Caminho do ffmpeg.exe (atual: {0}) [Enter=manter, B=procurar]"
        EnterFfprobePath         = "Caminho do ffprobe.exe (atual: {0}) [Enter=manter, B=procurar]"
        EnterYtdlpPath           = "Caminho do yt-dlp.exe (atual: {0}) [Enter=manter, B=procurar]"
        EnterDestDir             = "Pasta padrao de saida (atual: {0}, vazio = Downloads)"
        EnterEncoder             = "Codificador de video [auto / cpu / nvenc / amf / qsv] (atual: {0})"
        EnterCrf                 = "Valor de qualidade/CRF (atual: {0})"
        EnterChatWidth           = "Largura do chat em px (atual: {0})"
        EnterChatHeight          = "Altura do chat em px (atual: {0})"
        EnterFontSize            = "Tamanho da fonte do chat (atual: {0})"
        EnterTimestamps          = "Mostrar horarios? true/false (atual: {0})"
        EnterMarginLeft          = "Margem esquerda da sobreposicao em px (atual: {0})"
        EnterMarginTop           = "Margem superior da sobreposicao em px (atual: {0})"
        EnterBgOpacity           = "Opacidade do fundo 0.0-1.0 (atual: {0})"
        EnterAfterTaskMode       = "Apos terminar tarefa [ask=perguntar / continue=continuar / exit=sair / reset] (atual: {0})"
        CheckingTools            = "Verificando ferramentas externas..."
        ToolAutoDetected         = "Detectado automaticamente {0}: {1}"
        MissingToolsHeader       = "As seguintes ferramentas externas necessarias nao foram encontradas neste PC:"
        ConfigureToolPrompt      = "Configurar {0} ({1}):"
        ToolOptBrowse            = "  [1] Localizar {0} pelo Explorador de Arquivos"
        ToolOptWinget            = "  [2] Instalar automaticamente via winget ({0})"
        ToolOptDownload          = "  [2] Abrir pagina oficial de download no navegador e localizar {0}"
        ToolOptManual            = "  [3] Digitar o caminho completo manualmente"
        ToolOptSkip              = "  [4] Pular por enquanto"
        ChooseToolAction         = "Escolha uma opcao (1-4)"
        SelectExeDialog          = "Selecione {0}"
        TypeExePath              = "Digite o caminho completo para {0}"
        FileNotFoundWarn         = "Arquivo nao encontrado: {0}"
        InstallingWinget         = "Instalando {0} via winget..."
        WingetFailed             = "A instalacao via winget falhou ou foi cancelada (codigo {0})."
        WingetInstalledNotFound  = "winget concluiu, mas {0} nao foi detectado automaticamente. Localize-o manualmente."
        OpeningDownloadPage      = "Abrindo {0} no navegador. Baixe/extraia o arquivo e pressione Enter para selecionar {1}..."
        ToolConfigured           = "{0} configurado: {1}"
        ToolSkipped              = "{0} ignorado. Opcoes que dependem dele pedirao configuracao antes de executar."
        MissingRequiredAbort     = "Nao e possivel continuar: a ferramenta necessaria '{0}' nao esta configurada."
        EnterTarget              = "Digite o ID/URL do VOD da Twitch ou Nome/URL do canal"
        EnterVodOnly             = "Digite o ID ou URL do VOD da Twitch"
        ParseError               = "Nao foi possivel interpretar a entrada."
        InvalidVod               = "ID ou URL de VOD invalido."
        CheckingLive             = "Verificando se '{0}' esta ao vivo..."
        NotLiveFallback          = "'{0}' nao esta ao vivo no momento. Digite um ID/URL de VOD (ou Enter para sair)"
        ResolvingVod             = "Buscando o ultimo VOD arquivado de {0}..."
        NoVodYet                 = "Nenhum VOD arquivado encontrado ainda, tentando novamente em 30s..."
        FoundVod                 = "VOD encontrado: {0}"
        WaitingM3u8              = "Aguardando URL da playlist, tentando novamente em 15s..."
        DownloadingTs            = "Baixando segmentos .ts..."
        SavedChunk               = "Segmento {0}.ts salvo"
        WaitingChunk             = "Aguardando segmento {0} (HTTP {1}); ainda ao vivo. Aguardando 60s..."
        StreamOffline            = "A live encerrou. Todos os segmentos .ts foram baixados."
        DownloadingVod           = "Baixando VOD {0}..."
        DownloadVodErr           = "Falha ao baixar o VOD {0}."
        VideoReady               = "Video salvo em: {0}"
        DownloadingChat          = "Baixando chat do VOD {0}..."
        DownloadChatErr          = "Falha ao baixar o chat do VOD {0}."
        ChatSaved                = "Arquivo de chat salvo em: {0}"
        RenderingChat            = "Renderizando video do chat..."
        RenderChatErr            = "Falha ao renderizar o video do chat."
        BurningOverlay           = "Aplicando sobreposicao do chat no video..."
        BurnOverlayErr           = "Falha ao mesclar a sobreposicao no FFmpeg."
        MergedWithChat           = "Video com chat salvo em: {0}"
        SelectTsFolder           = "Selecione a pasta que contem os arquivos .ts..."
        NoTsFolder               = "Nenhuma pasta de origem selecionada."
        FolderNotFound           = "Pasta nao encontrada: {0}"
        NoTsFiles                = "Nenhum arquivo .ts encontrado em {0}"
        BuildingPlaylist         = "Montando lista para {0} arquivos .ts..."
        MergingTs                = "Mesclando segmentos .ts em {0}..."
        MergeTsErr               = "FFmpeg falhou ao juntar os arquivos .ts."
        JoinedSaved              = "Video mesclado salvo em: {0}"
        SelectVideoFile          = "Selecione o arquivo de video existente..."
        NoVideoFile              = "Nenhum arquivo de video valido selecionado."
        SelectSaveDest           = "Escolha a pasta de destino e o nome do arquivo na janela do Explorador..."
        SelectDestFolder         = "Selecione a pasta de destino (Cancelar para usar o padrao)..."
        VodLengthInfo            = "Duracao total do VOD: {0} ({1:N2}s)"
        VideoLengthInfo          = "Video selecionado:    {0} ({1:N2}s)"
        DiffLengthInfo           = "Diferenca (VOD - Video): {0:N2}s ({1})"
        LengthWarn               = "A duracao do video difere do VOD em {0:N2}s."
        OffsetPrompt             = "Digite o deslocamento inicial do video em segundos em relacao ao VOD (Enter para 0)"
        ChatRangeInfo            = "Sincronizando intervalo do chat: {0}s -> {1}s"
        DurationCompare          = "Duracao do video: {0:N2}s | Duracao do chat renderizado: {1:N2}s (dif: {2:N2}s)"
        DurationLockWarn         = "Diferenca de {0:N2}s detectada. Mantendo duracao exata do video ({1:N2}s)."
        SleepCountdown           = "Tarefa concluida. Colocando o PC em SUSPENDER em {0} minuto(s) ({1}s). Pressione Ctrl+C para cancelar."
        SleepTick                = "{0} - Suspendendo em ~{1} min ({2}s restantes)..."
        SleepingNow              = "{0} - Colocando o PC em SUSPENDER agora..."
        WokeUpPrompt             = "O PC voltou da suspensao. Continuar com {0}? (S/N)"
        StoppedAfterSleep        = "Processo interrompido antes de continuar. Arquivos baixados permanecem em '{0}'."
        CleanupPrompt            = "Excluir arquivos intermediarios (.ts, arquivos de chat, VOD sem chat)? (S/N)"
        CleanupDone              = "Limpeza concluida."
        DeleteTsPrompt           = "Excluir os arquivos .ts originais e filelist.txt em '{0}'? (S/N)"
        DeleteChatTemp           = "Excluir arquivos temporarios do chat (json/mp4)? (S/N)"
        ActConfig                = "Configuracao"
        ActLiveTs                = "Captura .ts ao vivo"
        ActVodFlow               = "Fluxo VOD / Transmissao"
        ActJoinTs                = "Juntar arquivos .ts"
        ActChatExisting          = "Chat em video existente"
        ActChatOnly              = "Baixar chat"
        ActChatPipeline          = "Chat e sobreposicao"
    }
}

$CFG              = $null
$LANG             = "en"
$RESOLVED_ENCODER = $null

function Msg([string]$Key) {
    if ($I18N.ContainsKey($LANG) -and $I18N[$LANG].ContainsKey($Key)) {
        return $I18N[$LANG][$Key]
    }
    return $I18N["en"][$Key]
}

function Fmt([string]$Key, [object[]]$Values = @()) {
    $template = Msg $Key
    if ($null -eq $Values -or $Values.Count -eq 0) {
        return $template
    }
    return ($template -f $Values)
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Load-Or-CreateConfig {
    $defaultObj = [pscustomobject]@{
        Language = ""
        Paths    = [pscustomobject]@{
            TwitchDownloaderCLI = "TwitchDownloaderCLI.exe"
            FFmpeg              = "ffmpeg.exe"
            FFprobe             = "ffprobe.exe"
            YtDlp               = "yt-dlp.exe"
            DefaultOutputDir    = ""
        }
        Encoding = [pscustomobject]@{
            Encoder       = "auto"
            Crf           = 20
            QualityPreset = "medium"
        }
        Chat     = [pscustomobject]@{
            Width          = 350
            Height         = 500
            FontSize       = 14
            ShowTimestamps = $false
            MarginLeft     = 50
            MarginTop      = 150
            BgOpacity      = 0.25
            EmbedImages    = $true
            Bttv           = $true
            Ffz            = $true
            SevenTv        = $true
        }
        Behavior = [pscustomobject]@{
            AskContinueAfterTask     = $null
            DefaultContinueAfterTask = $null
        }
    }

    if (-not (Test-Path $CONFIG_PATH -PathType Leaf)) {
        Write-Utf8NoBom -Path $CONFIG_PATH -Content ($defaultObj | ConvertTo-Json -Depth 5)
        return $defaultObj
    }

    try {
        $loaded = Get-Content -Path $CONFIG_PATH -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -eq $loaded.PSObject.Properties['Language']) {
            $loaded | Add-Member -NotePropertyName Language -NotePropertyValue "" -Force
        }
        if (-not $loaded.Paths)    { $loaded | Add-Member -NotePropertyName Paths -NotePropertyValue $defaultObj.Paths -Force }
        if (-not $loaded.Encoding) { $loaded | Add-Member -NotePropertyName Encoding -NotePropertyValue $defaultObj.Encoding -Force }
        if (-not $loaded.Chat)     { $loaded | Add-Member -NotePropertyName Chat -NotePropertyValue $defaultObj.Chat -Force }
        if (-not $loaded.Behavior) { $loaded | Add-Member -NotePropertyName Behavior -NotePropertyValue $defaultObj.Behavior -Force }

        foreach ($prop in $defaultObj.Paths.PSObject.Properties.Name) {
            if ($null -eq $loaded.Paths.$prop) { $loaded.Paths | Add-Member -NotePropertyName $prop -NotePropertyValue $defaultObj.Paths.$prop -Force }
        }
        foreach ($prop in $defaultObj.Encoding.PSObject.Properties.Name) {
            if ($null -eq $loaded.Encoding.$prop) { $loaded.Encoding | Add-Member -NotePropertyName $prop -NotePropertyValue $defaultObj.Encoding.$prop -Force }
        }
        foreach ($prop in $defaultObj.Chat.PSObject.Properties.Name) {
            if ($null -eq $loaded.Chat.$prop) { $loaded.Chat | Add-Member -NotePropertyName $prop -NotePropertyValue $defaultObj.Chat.$prop -Force }
        }
        foreach ($prop in $defaultObj.Behavior.PSObject.Properties.Name) {
            if ($null -eq $loaded.Behavior.PSObject.Properties[$prop]) {
                $loaded.Behavior | Add-Member -NotePropertyName $prop -NotePropertyValue $defaultObj.Behavior.$prop -Force
            }
        }
        return $loaded
    } catch {
        return $defaultObj
    }
}

function Save-Config($ConfigObj) {
    Write-Utf8NoBom -Path $CONFIG_PATH -Content ($ConfigObj | ConvertTo-Json -Depth 5)
}

function Read-YesNo([string]$PromptText) {
    while ($true) {
        $ans = (Read-Host $PromptText).Trim()
        if ($ans -match '^[YySs]$') { return $true }
        if ($ans -match '^[Nn]$')   { return $false }
        Write-Host (Msg "InvalidYesNo") -ForegroundColor Yellow
    }
}

function Get-AfterTaskModeLabel {
    if ($null -eq $CFG.Behavior.AskContinueAfterTask) { return "unset" }
    if ([bool]$CFG.Behavior.AskContinueAfterTask)     { return "ask" }
    if ([bool]$CFG.Behavior.DefaultContinueAfterTask) { return "continue" }
    return "exit"
}

function Invoke-AfterTaskPrompt {
    Write-Host ""
    $askSetting = $CFG.Behavior.AskContinueAfterTask

    # First time: ask Continue (Y/N), then ask whether to show every time (Y) or don't show again (N)
    if ($null -eq $askSetting) {
        $wantsContinue = Read-YesNo (Msg "ContinuePrompt")
        $showEveryTime = Read-YesNo (Msg "AskEveryTimePrompt")

        $CFG.Behavior.AskContinueAfterTask     = $showEveryTime
        $CFG.Behavior.DefaultContinueAfterTask = $wantsContinue
        Save-Config $CFG

        if ($wantsContinue) {
            Clear-Host
            return $true
        }
        return $false
    }

    # Show every time
    if ([bool]$askSetting) {
        $wantsContinue = Read-YesNo (Msg "ContinuePrompt")
        if ($wantsContinue) {
            Clear-Host
            return $true
        }
        return $false
    }

    # Don't show again: Enter clears & restarts (if Y) or closes (if N)
    if ([bool]$CFG.Behavior.DefaultContinueAfterTask) {
        Read-Host (Msg "PressEnterRestart") | Out-Null
        Clear-Host
        return $true
    } else {
        Read-Host (Msg "PressEnterClose") | Out-Null
        return $false
    }
}

function Ensure-LanguageConfigured {
    if (-not [string]::IsNullOrWhiteSpace($CFG.Language) -and $I18N.ContainsKey($CFG.Language)) {
        $script:LANG = $CFG.Language
        return
    }

    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "     Language Setup / Configuracao de Idioma" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "1. English"
    Write-Host "2. Portugues (BR)"
    Write-Host ""

    while ($true) {
        $langPick = (Read-Host "Select language / Selecione o idioma (1-2)").Trim()
        if ($langPick -eq "1") {
            $CFG.Language = "en"
            break
        } elseif ($langPick -eq "2") {
            $CFG.Language = "pt-BR"
            break
        }
        Write-Host "Please enter 1 or 2 / Por favor, digite 1 ou 2." -ForegroundColor Yellow
    }

    $script:LANG = $CFG.Language
    Save-Config $CFG
    Clear-Host
}

function Refresh-SessionPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $combined    = @($env:Path, $machinePath, $userPath) -join ';'

    $seen  = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $clean = New-Object 'System.Collections.Generic.List[string]'
    foreach ($entry in ($combined -split ';')) {
        $trimmed = $entry.Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmed) -and $seen.Add($trimmed)) {
            [void]$clean.Add($trimmed)
        }
    }
    $env:Path = ($clean -join ';')
}

function Get-EffectiveDestDir {
    if (-not [string]::IsNullOrWhiteSpace($CFG.Paths.DefaultOutputDir)) {
        return $CFG.Paths.DefaultOutputDir.Trim().Trim('"')
    }
    return $DOWNLOADS_DIR
}

function Get-ToolBinary([string]$Name) {
    if ($TOOL_SPECS.Contains($Name)) {
        $prop = $TOOL_SPECS[$Name].ConfigProp
        return $CFG.Paths.$prop
    }
    return $Name
}

function Get-CommonToolCandidatePaths([string]$ToolKey) {
    $exe = $TOOL_SPECS[$ToolKey].ExeName
    $patterns = New-Object 'System.Collections.Generic.List[string]'

    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\$exe"))
    }

    switch ($ToolKey) {
        "FFmpeg" {
            if ($env:LOCALAPPDATA) {
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\Gyan.FFmpeg*\*\bin\ffmpeg.exe"))
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\BtbN.FFmpeg*\*\bin\ffmpeg.exe"))
            }
            [void]$patterns.Add("C:\ffmpeg\bin\ffmpeg.exe")
            [void]$patterns.Add("C:\Program Files\ffmpeg\bin\ffmpeg.exe")
            [void]$patterns.Add("C:\ProgramData\chocolatey\bin\ffmpeg.exe")
        }
        "FFprobe" {
            if ($env:LOCALAPPDATA) {
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\Gyan.FFmpeg*\*\bin\ffprobe.exe"))
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\BtbN.FFmpeg*\*\bin\ffprobe.exe"))
            }
            [void]$patterns.Add("C:\ffmpeg\bin\ffprobe.exe")
            [void]$patterns.Add("C:\Program Files\ffmpeg\bin\ffprobe.exe")
            [void]$patterns.Add("C:\ProgramData\chocolatey\bin\ffprobe.exe")
        }
        "YtDlp" {
            if ($env:LOCALAPPDATA) {
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\yt-dlp.yt-dlp*\yt-dlp.exe"))
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Programs\yt-dlp\yt-dlp.exe"))
            }
            [void]$patterns.Add("C:\yt-dlp\yt-dlp.exe")
            [void]$patterns.Add("C:\ProgramData\chocolatey\bin\yt-dlp.exe")
        }
        "CLI" {
            if ($env:LOCALAPPDATA) {
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\*TwitchDownloader*\TwitchDownloaderCLI.exe"))
                [void]$patterns.Add((Join-Path $env:LOCALAPPDATA "Programs\TwitchDownloader*\TwitchDownloaderCLI.exe"))
            }
            [void]$patterns.Add("C:\Program Files\TwitchDownloader*\TwitchDownloaderCLI.exe")
            [void]$patterns.Add("C:\Tools\TwitchDownloader*\TwitchDownloaderCLI.exe")
        }
    }

    return $patterns
}

function Find-ToolExecutable([string]$ToolKey) {
    $spec       = $TOOL_SPECS[$ToolKey]
    $prop       = $spec.ConfigProp
    $exeName    = $spec.ExeName
    $configured = Clean-PathInput ([string]$CFG.Paths.$prop)

    # 1. Check currently configured value
    if (-not [string]::IsNullOrWhiteSpace($configured)) {
        if ($configured -match '[\\/]') {
            if (Test-Path -LiteralPath $configured -PathType Leaf) {
                return @{ Found = $true; Path = $configured; ConfigValue = $configured; Changed = $false }
            }
        } else {
            $cmd = Get-Command -Name $configured -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($cmd -and -not [string]::IsNullOrWhiteSpace($cmd.Source) -and (Test-Path -LiteralPath $cmd.Source -PathType Leaf)) {
                return @{ Found = $true; Path = $cmd.Source; ConfigValue = $configured; Changed = $false }
            }
        }
    }

    # 2. Check PATH by standard executable name
    $pathCmd = Get-Command -Name $exeName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pathCmd -and -not [string]::IsNullOrWhiteSpace($pathCmd.Source) -and (Test-Path -LiteralPath $pathCmd.Source -PathType Leaf)) {
        return @{ Found = $true; Path = $pathCmd.Source; ConfigValue = $exeName; Changed = ($configured -ne $exeName) }
    }

    # 3. Check sibling directory for FFmpeg <-> FFprobe
    if ($ToolKey -eq "FFprobe" -or $ToolKey -eq "FFmpeg") {
        $otherKey  = if ($ToolKey -eq "FFprobe") { "FFmpeg" } else { "FFprobe" }
        $otherProp = $TOOL_SPECS[$otherKey].ConfigProp
        $otherVal  = Clean-PathInput ([string]$CFG.Paths.$otherProp)
        $otherPath = $null

        if (-not [string]::IsNullOrWhiteSpace($otherVal)) {
            if ($otherVal -match '[\\/]' -and (Test-Path -LiteralPath $otherVal -PathType Leaf)) {
                $otherPath = $otherVal
            } else {
                $oCmd = Get-Command -Name $otherVal -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($oCmd -and $oCmd.Source) { $otherPath = $oCmd.Source }
            }
        }

        if ($otherPath) {
            $sibling = Join-Path (Split-Path -Path $otherPath -Parent) $exeName
            if (Test-Path -LiteralPath $sibling -PathType Leaf) {
                return @{ Found = $true; Path = $sibling; ConfigValue = $sibling; Changed = ($configured -ne $sibling) }
            }
        }
    }

    # 4. Check standard Windows installation directories (external to this script)
    foreach ($pattern in (Get-CommonToolCandidatePaths $ToolKey)) {
        $match = Get-Item -Path $pattern -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer } |
            Select-Object -First 1
        if ($match) {
            return @{ Found = $true; Path = $match.FullName; ConfigValue = $match.FullName; Changed = ($configured -ne $match.FullName) }
        }
    }

    return @{ Found = $false; Path = $null; ConfigValue = $null; Changed = $false }
}

function Sync-DetectedToolPath([string]$ToolKey, [bool]$AnnounceAutoDetect = $true) {
    $res = Find-ToolExecutable $ToolKey
    if ($res.Found) {
        if ($res.Changed) {
            $prop = $TOOL_SPECS[$ToolKey].ConfigProp
            $CFG.Paths.$prop = $res.ConfigValue
            Save-Config $CFG
            if ($AnnounceAutoDetect) {
                Write-Host (Fmt "ToolAutoDetected" @($TOOL_SPECS[$ToolKey].DisplayName, $res.Path)) -ForegroundColor Green
            }
        }
        return $true
    }
    return $false
}

function Select-ExecutableDialog {
    param(
        [string]$Title = "Select executable",
        [string]$ExeName = "*.exe"
    )
    $owner = New-Object System.Windows.Forms.Form
    $owner.TopMost = $true
    $owner.ShowInTaskbar = $false
    $owner.Opacity = 0
    $owner.Show()
    $owner.Hide()

    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = $Title
    $dlg.Filter = "$ExeName|$ExeName|Executable (*.exe)|*.exe|All Files (*.*)|*.*"
    $dlg.Multiselect = $false
    $dlg.CheckFileExists = $true

    $result = $dlg.ShowDialog($owner)
    $chosen = if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $dlg.FileName } else { $null }

    $dlg.Dispose()
    $owner.Dispose()

    return $chosen
}

function Invoke-MissingToolSetup([string]$ToolKey) {
    $spec      = $TOOL_SPECS[$ToolKey]
    $prop      = $spec.ConfigProp
    $exeName   = $spec.ExeName
    $hasWinget = [bool](Get-Command -Name "winget" -CommandType Application -ErrorAction SilentlyContinue)
    $canWinget = $hasWinget -and (-not [string]::IsNullOrWhiteSpace($spec.WingetId))

    while ($true) {
        Write-Host ""
        Write-Host (Fmt "ConfigureToolPrompt" @($spec.DisplayName, $exeName)) -ForegroundColor Yellow
        Write-Host (Fmt "ToolOptBrowse" @($exeName))
        if ($canWinget) {
            Write-Host (Fmt "ToolOptWinget" @($spec.WingetId))
        } else {
            Write-Host (Fmt "ToolOptDownload" @($exeName))
        }
        Write-Host (Msg "ToolOptManual")
        Write-Host (Msg "ToolOptSkip")

        $pick = (Read-Host (Msg "ChooseToolAction")).Trim()

        switch ($pick) {
            "1" {
                $chosen = Select-ExecutableDialog -Title (Fmt "SelectExeDialog" @($exeName)) -ExeName $exeName
                if (-not [string]::IsNullOrWhiteSpace($chosen) -and (Test-Path -LiteralPath $chosen -PathType Leaf)) {
                    $CFG.Paths.$prop = $chosen
                    Save-Config $CFG
                    Write-Host (Fmt "ToolConfigured" @($spec.DisplayName, $chosen)) -ForegroundColor Green
                    if ($ToolKey -eq "FFmpeg")  { [void](Sync-DetectedToolPath "FFprobe" $true) }
                    if ($ToolKey -eq "FFprobe") { [void](Sync-DetectedToolPath "FFmpeg"  $true) }
                    return $true
                }
            }
            "2" {
                if ($canWinget) {
                    Write-Host (Fmt "InstallingWinget" @($spec.DisplayName)) -ForegroundColor Cyan
                    & winget install -e --id $spec.WingetId --accept-package-agreements --accept-source-agreements
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host (Fmt "WingetFailed" @($LASTEXITCODE)) -ForegroundColor Red
                    }
                    Refresh-SessionPath
                    if (Sync-DetectedToolPath $ToolKey $true) {
                        if ($ToolKey -eq "FFmpeg")  { [void](Sync-DetectedToolPath "FFprobe" $true) }
                        if ($ToolKey -eq "FFprobe") { [void](Sync-DetectedToolPath "FFmpeg"  $true) }
                        $finalPath = (Find-ToolExecutable $ToolKey).Path
                        Write-Host (Fmt "ToolConfigured" @($spec.DisplayName, $finalPath)) -ForegroundColor Green
                        return $true
                    }
                    Write-Host (Fmt "WingetInstalledNotFound" @($exeName)) -ForegroundColor Yellow
                } else {
                    try { Start-Process $spec.DownloadUrl } catch {}
                    Read-Host (Fmt "OpeningDownloadPage" @($spec.DownloadUrl, $exeName)) | Out-Null
                    $chosen = Select-ExecutableDialog -Title (Fmt "SelectExeDialog" @($exeName)) -ExeName $exeName
                    if (-not [string]::IsNullOrWhiteSpace($chosen) -and (Test-Path -LiteralPath $chosen -PathType Leaf)) {
                        $CFG.Paths.$prop = $chosen
                        Save-Config $CFG
                        Write-Host (Fmt "ToolConfigured" @($spec.DisplayName, $chosen)) -ForegroundColor Green
                        if ($ToolKey -eq "FFmpeg")  { [void](Sync-DetectedToolPath "FFprobe" $true) }
                        if ($ToolKey -eq "FFprobe") { [void](Sync-DetectedToolPath "FFmpeg"  $true) }
                        return $true
                    }
                }
            }
            "3" {
                $typed = Clean-PathInput (Read-Host (Fmt "TypeExePath" @($exeName)))
                if (-not [string]::IsNullOrWhiteSpace($typed) -and (Test-Path -LiteralPath $typed -PathType Leaf)) {
                    $CFG.Paths.$prop = $typed
                    Save-Config $CFG
                    Write-Host (Fmt "ToolConfigured" @($spec.DisplayName, $typed)) -ForegroundColor Green
                    if ($ToolKey -eq "FFmpeg")  { [void](Sync-DetectedToolPath "FFprobe" $true) }
                    if ($ToolKey -eq "FFprobe") { [void](Sync-DetectedToolPath "FFmpeg"  $true) }
                    return $true
                }
                Write-Host (Fmt "FileNotFoundWarn" @($typed)) -ForegroundColor Red
            }
            "4" {
                Write-Host (Fmt "ToolSkipped" @($spec.DisplayName)) -ForegroundColor Yellow
                return $false
            }
            default {
                Write-Host (Msg "InvalidChoice") -ForegroundColor Red
            }
        }
    }
}

function Initialize-ToolPaths([string[]]$ToolKeys = @("CLI", "FFmpeg", "FFprobe", "YtDlp")) {
    Refresh-SessionPath

    $missing = New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in $ToolKeys) {
        if (-not (Sync-DetectedToolPath $key $true)) {
            [void]$missing.Add($key)
        }
    }

    if ($missing.Count -eq 0) {
        return $true
    }

    Write-Host ""
    Write-Host (Msg "MissingToolsHeader") -ForegroundColor Yellow
    foreach ($key in $missing) {
        Write-Host ("  - {0} ({1})" -f $TOOL_SPECS[$key].DisplayName, $TOOL_SPECS[$key].ExeName) -ForegroundColor Red
    }

    $allOk = $true
    foreach ($key in $missing) {
        if (Sync-DetectedToolPath $key $false) {
            continue
        }
        if (-not (Invoke-MissingToolSetup $key)) {
            $allOk = $false
        }
    }

    Write-Host ""
    return $allOk
}

function Assert-RequiredTools([string[]]$ToolKeys) {
    Refresh-SessionPath
    foreach ($key in $ToolKeys) {
        if (Sync-DetectedToolPath $key $true) {
            continue
        }
        $configured = Invoke-MissingToolSetup $key
        if (-not $configured -or -not (Sync-DetectedToolPath $key $false)) {
            Write-Host ("[ERROR] " + (Fmt "MissingRequiredAbort" @($TOOL_SPECS[$key].DisplayName))) -ForegroundColor Red
            return $false
        }
    }
    return $true
}

function Test-FFmpegEncoder([string]$EncoderName) {
    $ffmpeg = Get-ToolBinary "FFmpeg"
    & $ffmpeg -hide_banner -loglevel error -f lavfi -i "color=c=black:s=256x256:r=30:d=0.1" -frames:v 1 -pix_fmt yuv420p -c:v $EncoderName -f null - 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Resolve-VideoEncoderArgs {
    $enc = ($CFG.Encoding.Encoder).ToLowerInvariant()
    $q   = [int]$CFG.Encoding.Crf

    if ($enc -eq "auto") {
        if ($script:RESOLVED_ENCODER) {
            $enc = $script:RESOLVED_ENCODER
        } else {
            $encodersOut = (& (Get-ToolBinary "FFmpeg") -hide_banner -encoders 2>$null | Out-String)
            $gpuNames = ""
            try {
                $gpuNames = (Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop | Select-Object -ExpandProperty Name) -join " "
            } catch {
                try {
                    $gpuNames = (Get-WmiObject -Class Win32_VideoController -ErrorAction Stop | Select-Object -ExpandProperty Name) -join " "
                } catch {
                    $gpuNames = ""
                }
            }

            $candidates = New-Object System.Collections.Generic.List[string]
            if ([string]::IsNullOrWhiteSpace($gpuNames)) {
                @("nvenc", "amf", "qsv") | ForEach-Object { [void]$candidates.Add($_) }
            } else {
                if ($gpuNames -match "NVIDIA")         { [void]$candidates.Add("nvenc") }
                if ($gpuNames -match "AMD|Radeon|ATI") { [void]$candidates.Add("amf") }
                if ($gpuNames -match "Intel")          { [void]$candidates.Add("qsv") }
            }

            $enc = "cpu"
            foreach ($cand in $candidates) {
                $codecName = "h264_$cand"
                if (($encodersOut -match [regex]::Escape($codecName)) -and (Test-FFmpegEncoder $codecName)) {
                    $enc = $cand
                    break
                }
            }
            $script:RESOLVED_ENCODER = $enc
        }
    }

    switch ($enc) {
        "nvenc" { return @("-c:v", "h264_nvenc", "-preset", "p5", "-rc", "vbr", "-cq", "$q", "-pix_fmt", "yuv420p") }
        "amf"   { return @("-c:v", "h264_amf", "-quality", "quality", "-rc", "cqp", "-qp_i", "$q", "-qp_p", "$q", "-qp_b", "$([math]::Min(51, $q + 2))", "-pix_fmt", "yuv420p") }
        "qsv"   { return @("-c:v", "h264_qsv", "-global_quality", "$q", "-pix_fmt", "yuv420p") }
        default { return @("-c:v", "libx264", "-preset", $CFG.Encoding.QualityPreset, "-crf", "$q", "-pix_fmt", "yuv420p") }
    }
}

function Write-StepProgress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$Percent
    )
    $pct = [math]::Max(0, [math]::Min(100, $Percent))
    Write-Host ("[{0}/100%] {1} - {2}" -f $pct, $Activity, $Status) -ForegroundColor Cyan
    if ($pct -ge 100) {
        Write-Progress -Activity $Activity -Completed
    } else {
        Write-Progress -Activity $Activity -Status "$Status ($pct/100%)" -PercentComplete $pct
    }
}

function Clear-StepProgress([string]$Activity) {
    Write-Progress -Activity $Activity -Completed
}

function Format-Seconds([double]$Seconds) {
    if ($Seconds -lt 0) { $Seconds = 0 }
    $ts = [TimeSpan]::FromSeconds([math]::Round($Seconds))
    return ("{0:00}:{1:00}:{2:00}" -f [math]::Floor($ts.TotalHours), $ts.Minutes, $ts.Seconds)
}

function Invoke-SystemSleep {
    [Win32.PowerSuspend]::SetSuspendState($false, $false, $false) | Out-Null
}

function Invoke-SleepCountdown([Nullable[double]]$SleepMinutes) {
    if ($null -eq $SleepMinutes -or $SleepMinutes -le 0) {
        return
    }
    $totalSeconds = [int][math]::Round($SleepMinutes * 60.0)
    Write-Host ("`n" + (Fmt "SleepCountdown" @($SleepMinutes, $totalSeconds))) -ForegroundColor Yellow

    $remaining = $totalSeconds
    while ($remaining -gt 0) {
        $minsLeft = [math]::Ceiling($remaining / 60.0)
        Write-Host (Fmt "SleepTick" @((Get-Date -Format 'HH:mm:ss'), $minsLeft, $remaining)) -ForegroundColor Yellow
        $step = [math]::Min(60, $remaining)
        Start-Sleep -Seconds $step
        $remaining -= $step
    }

    Write-Host (Fmt "SleepingNow" @((Get-Date -Format 'HH:mm:ss'))) -ForegroundColor Green
    Invoke-SystemSleep
}

function Invoke-SleepAndAskContinue([Nullable[double]]$SleepMinutes, [string]$NextActionLabel) {
    if ($null -eq $SleepMinutes -or $SleepMinutes -le 0) {
        return $true
    }
    Invoke-SleepCountdown -SleepMinutes $SleepMinutes

    Write-Host ""
    $ans = Read-Host (Fmt "WokeUpPrompt" @($NextActionLabel))
    return ($ans -match '^[YySs]$')
}

function Select-FolderDialog {
    param(
        [string]$Description = "Select a folder",
        [string]$InitialDirectory = $DOWNLOADS_DIR,
        [string]$FallbackPath = $null
    )
    $owner = New-Object System.Windows.Forms.Form
    $owner.TopMost = $true
    $owner.ShowInTaskbar = $false
    $owner.Opacity = 0
    $owner.Show()
    $owner.Hide()

    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Description
    if ($dlg.PSObject.Properties.Match('UseDescriptionForTitle').Count -gt 0) {
        $dlg.UseDescriptionForTitle = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($InitialDirectory) -and (Test-Path $InitialDirectory -PathType Container)) {
        $dlg.SelectedPath = $InitialDirectory
    }

    $result = $dlg.ShowDialog($owner)
    $chosen = if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $dlg.SelectedPath } else { $null }

    $dlg.Dispose()
    $owner.Dispose()

    if ([string]::IsNullOrWhiteSpace($chosen)) {
        return $FallbackPath
    }
    return $chosen
}

function Select-VideoFileDialog {
    param(
        [string]$Title = "Select an existing video file",
        [string]$InitialDirectory = $DOWNLOADS_DIR
    )
    $owner = New-Object System.Windows.Forms.Form
    $owner.TopMost = $true
    $owner.ShowInTaskbar = $false
    $owner.Opacity = 0
    $owner.Show()
    $owner.Hide()

    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = $Title
    $dlg.Filter = "Video Files (*.mp4;*.mkv;*.ts;*.webm;*.mov;*.avi)|*.mp4;*.mkv;*.ts;*.webm;*.mov;*.avi|All Files (*.*)|*.*"
    $dlg.Multiselect = $false
    if (-not [string]::IsNullOrWhiteSpace($InitialDirectory) -and (Test-Path $InitialDirectory -PathType Container)) {
        $dlg.InitialDirectory = $InitialDirectory
    }

    $result = $dlg.ShowDialog($owner)
    $chosen = if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $dlg.FileName } else { $null }

    $dlg.Dispose()
    $owner.Dispose()

    return $chosen
}

function Select-SaveFileDialog {
    param(
        [string]$Title = "Save file",
        [string]$Filter = "MP4 Video (*.mp4)|*.mp4|All Files (*.*)|*.*",
        [string]$DefaultExt = "mp4",
        [string]$InitialDirectory = $DOWNLOADS_DIR,
        [string]$DefaultFileName = "output.mp4",
        [string]$FallbackPath = $null
    )
    $owner = New-Object System.Windows.Forms.Form
    $owner.TopMost = $true
    $owner.ShowInTaskbar = $false
    $owner.Opacity = 0
    $owner.Show()
    $owner.Hide()

    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Title = $Title
    $dlg.Filter = $Filter
    $dlg.DefaultExt = $DefaultExt
    $dlg.AddExtension = $true
    $dlg.OverwritePrompt = $true
    $dlg.FileName = $DefaultFileName
    if (-not [string]::IsNullOrWhiteSpace($InitialDirectory) -and (Test-Path $InitialDirectory -PathType Container)) {
        $dlg.InitialDirectory = $InitialDirectory
    }

    $result = $dlg.ShowDialog($owner)
    $chosen = if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $dlg.FileName } else { $null }

    $dlg.Dispose()
    $owner.Dispose()

    if ([string]::IsNullOrWhiteSpace($chosen)) {
        return $FallbackPath
    }
    $parent = Split-Path -Path $chosen -Parent
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    return $chosen
}

function Clean-PathInput([string]$raw) {
    if ([string]::IsNullOrWhiteSpace($raw)) { return "" }
    return $raw.Trim().Trim('"').Trim("'")
}

function Try-ParseDoubleFlexible([string]$raw, [ref]$outVal) {
    if ([string]::IsNullOrWhiteSpace($raw)) { return $false }
    $trimmed = $raw.Trim()
    if ([double]::TryParse($trimmed, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, $outVal)) {
        return $true
    }
    return [double]::TryParse($trimmed, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::CurrentCulture, $outVal)
}

function Parse-Target([string]$rawInput) {
    $clean = (Clean-PathInput $rawInput) -replace '\?.*$', ''
    if ($clean -match 'twitch\.tv/videos/(\d+)' -or $clean -match '^v?(\d+)$') {
        return @{ Type = "VOD"; Value = $Matches[1] }
    }
    $ch = ($clean -replace '^https?://(www\.)?twitch\.tv/', '').Trim('/')
    $ch = ($ch -split '/')[0]
    if (-not [string]::IsNullOrWhiteSpace($ch)) {
        return @{ Type = "CHANNEL"; Value = $ch }
    }
    return $null
}

function Get-ChatEmoteArgs([string]$OutputPath) {
    $result = @()
    $isTxt  = ($OutputPath -match '\.txt$')
    if ([bool]$CFG.Chat.EmbedImages -and (-not $isTxt)) {
        $bttv = if ([bool]$CFG.Chat.Bttv)    { "true" } else { "false" }
        $ffz  = if ([bool]$CFG.Chat.Ffz)     { "true" } else { "false" }
        $stv  = if ([bool]$CFG.Chat.SevenTv) { "true" } else { "false" }
        $result += @(
            "--embed-images",
            "--bttv=$bttv",
            "--ffz=$ffz",
            "--stv=$stv"
        )
    }
    return $result
}

function Get-MediaDuration([string]$filePath) {
    $ffprobe = Get-ToolBinary "FFprobe"
    $cmd = Get-Command $ffprobe -ErrorAction SilentlyContinue
    if (-not $cmd -and -not (Test-Path $ffprobe -PathType Leaf)) {
        return $null
    }
    $durStr = & $ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $filePath 2>$null
    $dur = 0.0
    if ([double]::TryParse($durStr, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$dur)) {
        return $dur
    }
    return $null
}

function Get-VodDurationFromUrl([string]$VodUrl) {
    $ytdlp = Get-ToolBinary "YtDlp"
    $rawDur = (& $ytdlp --no-warnings --print duration $VodUrl 2>$null | Select-Object -Last 1)
    if ($rawDur) {
        $sec = 0.0
        if ([double]::TryParse($rawDur.Trim(), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$sec) -and $sec -gt 0) {
            return $sec
        }
    }

    $rawStr = (& $ytdlp --no-warnings --print duration_string $VodUrl 2>$null | Select-Object -Last 1)
    if ($rawStr) {
        $parts = $rawStr.Trim().Split(':')
        if ($parts.Count -eq 3) {
            return ([double]$parts[0] * 3600.0) + ([double]$parts[1] * 60.0) + [double]$parts[2]
        } elseif ($parts.Count -eq 2) {
            return ([double]$parts[0] * 60.0) + [double]$parts[1]
        }
    }
    return $null
}

function Build-TsPlaylist([string]$tsDir) {
    if (-not (Test-Path $tsDir -PathType Container)) {
        Write-Host ("[ERROR] " + (Fmt "FolderNotFound" @($tsDir))) -ForegroundColor Red
        return $null
    }
    $tsFiles = Get-ChildItem -Path $tsDir -Filter "*.ts" |
        Where-Object { $_.BaseName -match '^\d+$' } |
        Sort-Object { [int]$_.BaseName }

    if ($tsFiles.Count -eq 0) {
        $tsFiles = Get-ChildItem -Path $tsDir -Filter "*.ts" | Sort-Object Name
    }
    if ($tsFiles.Count -eq 0) {
        Write-Host ("[ERROR] " + (Fmt "NoTsFiles" @($tsDir))) -ForegroundColor Red
        return $null
    }

    $listFile = Join-Path $tsDir "filelist.txt"
    [string[]]$lines = $tsFiles | ForEach-Object {
        $escaped = $_.FullName -replace "'", "'\''"
        "file '$escaped'"
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($listFile, $lines, $utf8NoBom)

    return @{ ListFile = $listFile; Count = $tsFiles.Count }
}

function Join-TsFiles([string]$tsDir, [string]$outputFile) {
    $act = Msg "ActJoinTs"
    Write-StepProgress -Activity $act -Status (Msg "SelectTsFolder") -Percent 0

    $info = Build-TsPlaylist -tsDir $tsDir
    if (-not $info) {
        Clear-StepProgress $act
        return $false
    }

    Write-StepProgress -Activity $act -Status (Fmt "BuildingPlaylist" @($info.Count)) -Percent 25
    Write-StepProgress -Activity $act -Status (Fmt "MergingTs" @($outputFile)) -Percent 50

    $ffmpeg = Get-ToolBinary "FFmpeg"
    & $ffmpeg -y -nostdin -f concat -safe 0 -i $info.ListFile -c copy $outputFile
    if ($LASTEXITCODE -ne 0) {
        Clear-StepProgress $act
        Write-Host ("[ERROR] " + (Msg "MergeTsErr")) -ForegroundColor Red
        return $false
    }

    Write-StepProgress -Activity $act -Status (Fmt "JoinedSaved" @($outputFile)) -Percent 100
    Write-Host (Fmt "JoinedSaved" @($outputFile)) -ForegroundColor Green
    return $true
}

function Invoke-ChatDownloadOnly {
    param(
        [string]$VodId,
        [string]$OutputPath
    )
    $act = Msg "ActChatOnly"
    $cli = Get-ToolBinary "CLI"
    Write-StepProgress -Activity $act -Status (Fmt "DownloadingChat" @($VodId)) -Percent 15
    Clear-StepProgress $act

    $argsList = @("chatdownload", "--id", $VodId)
    $argsList += (Get-ChatEmoteArgs -OutputPath $OutputPath)
    $argsList += @("-o", $OutputPath)

    & $cli @argsList
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutputPath)) {
        Write-Host ("[ERROR] " + (Fmt "DownloadChatErr" @($VodId))) -ForegroundColor Red
        return $false
    }

    Write-StepProgress -Activity $act -Status (Fmt "ChatSaved" @($OutputPath)) -Percent 100
    Write-Host (Fmt "ChatSaved" @($OutputPath)) -ForegroundColor Green
    return $true
}

function Invoke-ChatRenderAndMerge {
    param(
        [string]$VodId,
        [string]$VideoFile,
        [string]$FinalOutput,
        [string]$WorkDir,
        [bool]$CheckSync = $false,
        [string]$VodUrl = $null,
        [bool]$Unattended = $false
    )

    $act    = Msg "ActChatPipeline"
    $cli    = Get-ToolBinary "CLI"
    $ffmpeg = Get-ToolBinary "FFmpeg"
    Write-StepProgress -Activity $act -Status (Fmt "DownloadingChat" @($VodId)) -Percent 0

    $chatJson  = Join-Path $WorkDir "chat_$VodId.json"
    $chatVideo = Join-Path $WorkDir "chat_$VodId.mp4"

    $effectiveVodUrl = if ([string]::IsNullOrWhiteSpace($VodUrl)) { "https://www.twitch.tv/videos/$VodId" } else { $VodUrl }
    $vodDur   = $null
    $videoDur = Get-MediaDuration $VideoFile
    $beginSec = 0
    $endSec   = $null

    if ($CheckSync -and (-not $Unattended)) {
        $vodDur = Get-VodDurationFromUrl -VodUrl $effectiveVodUrl
        if ($vodDur -and $videoDur) {
            $delta = $vodDur - $videoDur
            Write-Host (Fmt "VodLengthInfo" @((Format-Seconds $vodDur), $vodDur)) -ForegroundColor Cyan
            Write-Host (Fmt "VideoLengthInfo" @((Format-Seconds $videoDur), $videoDur)) -ForegroundColor Cyan
            Write-Host (Fmt "DiffLengthInfo" @($delta, (Format-Seconds ([math]::Abs($delta))))) -ForegroundColor Yellow
            if ([math]::Abs($delta) -gt 3.0) {
                Write-Warning (Fmt "LengthWarn" @([math]::Abs($delta)))
            }
        }
        if ($videoDur) {
            $offsetInput = Read-Host (Msg "OffsetPrompt")
            $parsedOffset = 0.0
            if (Try-ParseDoubleFlexible -raw $offsetInput -outVal ([ref]$parsedOffset)) {
                $beginSec = [math]::Max(0, [math]::Floor($parsedOffset))
            } else {
                $beginSec = 0
            }
            $endSec = [math]::Ceiling($beginSec + $videoDur)
            if ($vodDur -and $endSec -gt [math]::Ceiling($vodDur)) {
                $endSec = [math]::Ceiling($vodDur)
            }
        }
    }

    Write-StepProgress -Activity $act -Status (Fmt "DownloadingChat" @($VodId)) -Percent 15
    Clear-StepProgress $act
    $chatArgs = @("chatdownload", "--id", $VodId)
    $chatArgs += (Get-ChatEmoteArgs -OutputPath $chatJson)
    $chatArgs += @("-o", $chatJson)
    if ($CheckSync -and $videoDur -and ($null -ne $endSec)) {
        $chatArgs += @("-b", "$beginSec", "-e", "$endSec")
        Write-Host (Fmt "ChatRangeInfo" @($beginSec, $endSec)) -ForegroundColor Yellow
    }

    & $cli @chatArgs
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $chatJson)) {
        Write-Host ("[ERROR] " + (Fmt "DownloadChatErr" @($VodId))) -ForegroundColor Red
        return $null
    }

    Write-StepProgress -Activity $act -Status (Msg "RenderingChat") -Percent 40
    Clear-StepProgress $act
    $w  = [int]$CFG.Chat.Width
    $h  = [int]$CFG.Chat.Height
    $fs = [int]$CFG.Chat.FontSize
    $encArgsStr = ((Resolve-VideoEncoderArgs) -join " ")

    $renderArgs = @(
        "chatrender",
        "-i", $chatJson,
        "-w", "$w",
        "-h", "$h",
        "--font-size", "$fs",
        "--background-color", "#00000000",
        "--ffmpeg-path", $ffmpeg,
        "--output-args=$encArgsStr `"{save_path}`"",
        "-o", $chatVideo
    )
    if ([bool]$CFG.Chat.ShowTimestamps) { $renderArgs += "--timestamp=true" }

    & $cli @renderArgs
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $chatVideo)) {
        Write-Host ("[ERROR] " + (Msg "RenderChatErr")) -ForegroundColor Red
        return $null
    }

    Write-StepProgress -Activity $act -Status (Msg "BurningOverlay") -Percent 65
    $chatDur = Get-MediaDuration $chatVideo
    if ($videoDur -and $chatDur) {
        $diff = [math]::Abs($videoDur - $chatDur)
        Write-Host (Fmt "DurationCompare" @($videoDur, $chatDur, $diff)) -ForegroundColor Cyan
        if ($diff -gt 2.0) {
            Write-Warning (Fmt "DurationLockWarn" @($diff, $videoDur))
        }
    }

    Write-StepProgress -Activity $act -Status (Msg "BurningOverlay") -Percent 75
    Clear-StepProgress $act
    $ml    = [int]$CFG.Chat.MarginLeft
    $mt    = [int]$CFG.Chat.MarginTop
    $opStr = ([double]$CFG.Chat.BgOpacity).ToString([System.Globalization.CultureInfo]::InvariantCulture)
    $filter = "[0:v]drawbox=x=${ml}:y=${mt}:w=${w}:h=${h}:color=black@${opStr}:t=fill[bg];[1:v]colorkey=0x000000:0.15:0.1,format=yuva420p[fg];[bg][fg]overlay=${ml}:${mt}:format=auto:eof_action=pass[v]"

    $ffArgs = @("-y", "-nostdin", "-i", $VideoFile, "-i", $chatVideo, "-filter_complex", $filter, "-map", "[v]", "-map", "0:a")
    $ffArgs += (Resolve-VideoEncoderArgs)
    $ffArgs += @("-c:a", "copy")
    if ($videoDur) {
        $ffArgs += @("-t", ($videoDur.ToString([System.Globalization.CultureInfo]::InvariantCulture)))
    }
    $ffArgs += $FinalOutput

    & $ffmpeg @ffArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("[ERROR] " + (Msg "BurnOverlayErr")) -ForegroundColor Red
        return $null
    }

    Write-StepProgress -Activity $act -Status (Fmt "MergedWithChat" @($FinalOutput)) -Percent 100
    Write-Host (Fmt "MergedWithChat" @($FinalOutput)) -ForegroundColor Green
    return @{ ChatJson = $chatJson; ChatVideo = $chatVideo }
}

function Invoke-LiveTsDownloadOnly {
    param(
        [string]$Channel,
        [string]$DestDir
    )
    $act   = Msg "ActLiveTs"
    $ytdlp = Get-ToolBinary "YtDlp"
    Write-StepProgress -Activity $act -Status (Fmt "ResolvingVod" @($Channel)) -Percent 0

    $vid = ""
    while ([string]::IsNullOrWhiteSpace($vid)) {
        $found = (& $ytdlp --playlist-items 1 --print id "https://www.twitch.tv/$Channel/videos?filter=archives&sort=time" 2>$null | Select-Object -Last 1)
        if ($found) {
            $vid = ($found.Trim() -replace '^v', '')
            break
        }
        Write-StepProgress -Activity $act -Status (Msg "NoVodYet") -Percent 5
        Start-Sleep -Seconds 30
    }

    Write-StepProgress -Activity $act -Status (Fmt "FoundVod" @($vid)) -Percent 15
    $m3u8 = ""
    while ([string]::IsNullOrWhiteSpace($m3u8)) {
        $m3u8 = (& $ytdlp -f "1080p60/best" --get-url "https://www.twitch.tv/videos/$vid" 2>$null | Select-Object -First 1)
        if (-not $m3u8) {
            Write-StepProgress -Activity $act -Status (Msg "WaitingM3u8") -Percent 18
            Start-Sleep -Seconds 15
        }
    }

    $baseUrl   = $m3u8 -replace '/[^/]*\.m3u8.*$', ''
    $chunkDir  = Join-Path $DestDir "ts_chunks_$vid"
    $mergedMp4 = Join-Path $DestDir "vod_${vid}_live_merged.mp4"
    New-Item -ItemType Directory -Force -Path $chunkDir | Out-Null

    Write-StepProgress -Activity $act -Status (Msg "DownloadingTs") -Percent 25

    $i = 0
    while ($true) {
        $outFile = Join-Path $chunkDir "$i.ts"
        if (Test-Path $outFile) { $i++; continue }

        $code = curl.exe -s -L -o $outFile -w "%{http_code}" "$baseUrl/$i.ts"
        if ($code -eq "200" -and (Test-Path $outFile) -and ((Get-Item $outFile).Length -gt 0)) {
            if ($i % 25 -eq 0) {
                $livePct = [math]::Min(95, 25 + [math]::Floor(($i / 2000.0) * 70))
                Write-StepProgress -Activity $act -Status (Fmt "SavedChunk" @($i)) -Percent $livePct
            }
            $i++
        } else {
            if (Test-Path $outFile) { Remove-Item $outFile -Force }

            $liveStatus = (& $ytdlp --print is_live "https://www.twitch.tv/$Channel" 2>$null | Out-String).Trim()
            if ($liveStatus -notmatch 'True') {
                Write-StepProgress -Activity $act -Status (Msg "StreamOffline") -Percent 100
                return @{ VodId = $vid; MergedFile = $mergedMp4; ChunkDir = $chunkDir }
            } else {
                Write-Host (Fmt "WaitingChunk" @($i, $code))
                Start-Sleep -Seconds 60
            }
        }
    }
}

function Read-ToolPathConfigPrompt([string]$ToolKey, [string]$PromptKey) {
    $spec    = $TOOL_SPECS[$ToolKey]
    $prop    = $spec.ConfigProp
    $exeName = $spec.ExeName
    $v       = Read-Host (Fmt $PromptKey @($CFG.Paths.$prop))

    if ([string]::IsNullOrWhiteSpace($v)) {
        return
    }
    if ($v.Trim().ToLowerInvariant() -eq "b") {
        $chosen = Select-ExecutableDialog -Title (Fmt "SelectExeDialog" @($exeName)) -ExeName $exeName
        if (-not [string]::IsNullOrWhiteSpace($chosen) -and (Test-Path -LiteralPath $chosen -PathType Leaf)) {
            $CFG.Paths.$prop = $chosen
            Write-Host (Fmt "ToolConfigured" @($spec.DisplayName, $chosen)) -ForegroundColor Green
        }
    } else {
        $CFG.Paths.$prop = Clean-PathInput $v
    }
}

function Invoke-ConfigurationMenu {
    $act = Msg "ActConfig"
    Write-StepProgress -Activity $act -Status "Updating config.json" -Percent 10
    Clear-StepProgress $act

    $langChoice = Read-Host (Msg "SelectLang")
    if ($langChoice -eq "2") {
        $CFG.Language = "pt-BR"
    } elseif ($langChoice -eq "1") {
        $CFG.Language = "en"
    }
    $script:LANG = $CFG.Language

    Read-ToolPathConfigPrompt -ToolKey "CLI"     -PromptKey "EnterCliPath"
    Read-ToolPathConfigPrompt -ToolKey "FFmpeg"  -PromptKey "EnterFfmpegPath"
    Read-ToolPathConfigPrompt -ToolKey "FFprobe" -PromptKey "EnterFfprobePath"
    Read-ToolPathConfigPrompt -ToolKey "YtDlp"   -PromptKey "EnterYtdlpPath"

    $v = Read-Host (Fmt "EnterDestDir" @($CFG.Paths.DefaultOutputDir))
    if (-not [string]::IsNullOrWhiteSpace($v)) { $CFG.Paths.DefaultOutputDir = Clean-PathInput $v }

    $v = Read-Host (Fmt "EnterEncoder" @($CFG.Encoding.Encoder))
    if (-not [string]::IsNullOrWhiteSpace($v)) {
        $CFG.Encoding.Encoder = $v.Trim().ToLowerInvariant()
        $script:RESOLVED_ENCODER = $null
    }

    $tmpInt = 0
    $v = Read-Host (Fmt "EnterCrf" @($CFG.Encoding.Crf))
    if (-not [string]::IsNullOrWhiteSpace($v) -and [int]::TryParse($v.Trim(), [ref]$tmpInt)) { $CFG.Encoding.Crf = $tmpInt }

    $v = Read-Host (Fmt "EnterChatWidth" @($CFG.Chat.Width))
    if (-not [string]::IsNullOrWhiteSpace($v) -and [int]::TryParse($v.Trim(), [ref]$tmpInt)) { $CFG.Chat.Width = $tmpInt }

    $v = Read-Host (Fmt "EnterChatHeight" @($CFG.Chat.Height))
    if (-not [string]::IsNullOrWhiteSpace($v) -and [int]::TryParse($v.Trim(), [ref]$tmpInt)) { $CFG.Chat.Height = $tmpInt }

    $v = Read-Host (Fmt "EnterFontSize" @($CFG.Chat.FontSize))
    if (-not [string]::IsNullOrWhiteSpace($v) -and [int]::TryParse($v.Trim(), [ref]$tmpInt)) { $CFG.Chat.FontSize = $tmpInt }

    $v = Read-Host (Fmt "EnterTimestamps" @($CFG.Chat.ShowTimestamps))
    if (-not [string]::IsNullOrWhiteSpace($v) -and ($v.Trim().ToLowerInvariant() -match '^(true|false)$')) {
        $CFG.Chat.ShowTimestamps = [bool]::Parse($v.Trim())
    }

    $v = Read-Host (Fmt "EnterMarginLeft" @($CFG.Chat.MarginLeft))
    if (-not [string]::IsNullOrWhiteSpace($v) -and [int]::TryParse($v.Trim(), [ref]$tmpInt)) { $CFG.Chat.MarginLeft = $tmpInt }

    $v = Read-Host (Fmt "EnterMarginTop" @($CFG.Chat.MarginTop))
    if (-not [string]::IsNullOrWhiteSpace($v) -and [int]::TryParse($v.Trim(), [ref]$tmpInt)) { $CFG.Chat.MarginTop = $tmpInt }

    $v = Read-Host (Fmt "EnterBgOpacity" @($CFG.Chat.BgOpacity))
    $tmpOp = 0.0
    if (Try-ParseDoubleFlexible -raw $v -outVal ([ref]$tmpOp)) {
        $CFG.Chat.BgOpacity = [math]::Max(0.0, [math]::Min(1.0, $tmpOp))
    }

    $v = Read-Host (Fmt "EnterAfterTaskMode" @((Get-AfterTaskModeLabel)))
    if (-not [string]::IsNullOrWhiteSpace($v)) {
        switch ($v.Trim().ToLowerInvariant()) {
            "ask" {
                $CFG.Behavior.AskContinueAfterTask = $true
            }
            "continue" {
                $CFG.Behavior.AskContinueAfterTask     = $false
                $CFG.Behavior.DefaultContinueAfterTask = $true
            }
            "exit" {
                $CFG.Behavior.AskContinueAfterTask     = $false
                $CFG.Behavior.DefaultContinueAfterTask = $false
            }
            "reset" {
                $CFG.Behavior.AskContinueAfterTask     = $null
                $CFG.Behavior.DefaultContinueAfterTask = $null
            }
        }
    }

    Save-Config $CFG
    Write-StepProgress -Activity $act -Status (Fmt "ConfigSaved" @($CONFIG_PATH)) -Percent 100
    Write-Host (Fmt "ConfigSaved" @($CONFIG_PATH)) -ForegroundColor Green
    Write-Host ""
}

# ==========================================
# INITIALIZE: CONFIG -> LANGUAGE -> TOOLS -> MENU
# ==========================================
$CFG = Load-Or-CreateConfig
Ensure-LanguageConfigured
[void](Initialize-ToolPaths)

while ($true) {
    $DEST_DIR = Get-EffectiveDestDir
    New-Item -ItemType Directory -Force -Path $DEST_DIR | Out-Null

    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ("      " + (Msg "Title")) -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host (Msg "Opt0")
    Write-Host (Msg "Opt1")
    Write-Host (Msg "Opt2")
    Write-Host (Msg "Opt3")
    Write-Host (Msg "Opt4")
    Write-Host (Msg "Opt5")
    Write-Host ""

    $choice = (Read-Host (Msg "SelectOption")).Trim()

    if ($choice -notin @("0", "1", "2", "3", "4", "5")) {
        Write-Host ("[ERROR] " + (Msg "InvalidChoice")) -ForegroundColor Red
        Write-Host ""
        continue
    }

    if ($choice -eq "0") {
        Invoke-ConfigurationMenu
        [void](Initialize-ToolPaths)
    } else {
        $sleepMinutes = $null
        if ($choice -ne "5") {
            $sleepMinutesInput = Read-Host (Msg "SleepPrompt")
            if (-not [string]::IsNullOrWhiteSpace($sleepMinutesInput)) {
                $parsedMins = 0.0
                if (Try-ParseDoubleFlexible -raw $sleepMinutesInput -outVal ([ref]$parsedMins)) {
                    if ($parsedMins -gt 0) {
                        $sleepMinutes = $parsedMins
                        Write-Host (Fmt "SleepScheduled" @($sleepMinutes)) -ForegroundColor Yellow
                    }
                } else {
                    Write-Warning (Fmt "InvalidSleep" @($sleepMinutesInput))
                }
            }
        }

        $hasSleep = ($null -ne $sleepMinutes -and $sleepMinutes -gt 0)

        switch ($choice) {
            "3" {
                if (-not (Assert-RequiredTools @("FFmpeg"))) { break }
                $act = Msg "ActJoinTs"
                Write-StepProgress -Activity $act -Status (Msg "SelectTsFolder") -Percent 0
                Clear-StepProgress $act
                Write-Host (Msg "SelectTsFolder") -ForegroundColor Yellow
                $tsDir = Select-FolderDialog -Description (Msg "SelectTsFolder") -InitialDirectory $DEST_DIR -FallbackPath $null
                if ([string]::IsNullOrWhiteSpace($tsDir)) {
                    Write-Host ("[ERROR] " + (Msg "NoTsFolder")) -ForegroundColor Red
                    break
                }

                Write-Host (Msg "SelectSaveDest") -ForegroundColor Yellow
                $defaultName = "joined_ts_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".mp4"
                $outFile = Select-SaveFileDialog -Title (Msg "SelectSaveDest") -InitialDirectory $DOWNLOADS_DIR -DefaultFileName $defaultName -FallbackPath (Join-Path $DOWNLOADS_DIR $defaultName)

                $ok = Join-TsFiles -tsDir $tsDir -outputFile $outFile
                if ($ok) {
                    if ($hasSleep) {
                        Invoke-SleepCountdown -SleepMinutes $sleepMinutes
                    } else {
                        $del = Read-Host (Fmt "DeleteTsPrompt" @($tsDir))
                        if ($del -match '^[YySs]$') {
                            Remove-Item (Join-Path $tsDir "*.ts") -Force -ErrorAction SilentlyContinue
                            Remove-Item (Join-Path $tsDir "filelist.txt") -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                break
            }

            "4" {
                if (-not (Assert-RequiredTools @("CLI", "FFmpeg", "FFprobe", "YtDlp"))) { break }
                $act = Msg "ActChatExisting"
                Write-StepProgress -Activity $act -Status (Msg "EnterVodOnly") -Percent 0
                Clear-StepProgress $act
                $vodRaw = Read-Host (Msg "EnterVodOnly")
                $parsed = Parse-Target $vodRaw
                if (-not $parsed -or $parsed.Type -ne "VOD") {
                    Write-Host ("[ERROR] " + (Msg "InvalidVod")) -ForegroundColor Red
                    break
                }
                $vodId  = $parsed.Value
                $vodUrl = if ((Clean-PathInput $vodRaw) -match '^https?://') { Clean-PathInput $vodRaw } else { "https://www.twitch.tv/videos/$vodId" }

                Write-Host (Msg "SelectVideoFile") -ForegroundColor Yellow
                $existingVideo = Select-VideoFileDialog -Title (Msg "SelectVideoFile") -InitialDirectory $DEST_DIR
                if ([string]::IsNullOrWhiteSpace($existingVideo) -or -not (Test-Path $existingVideo -PathType Leaf)) {
                    Write-Host ("[ERROR] " + (Msg "NoVideoFile")) -ForegroundColor Red
                    break
                }

                Write-Host (Msg "SelectSaveDest") -ForegroundColor Yellow
                $defaultOut = Join-Path $DOWNLOADS_DIR "vod_${vodId}_with_chat.mp4"
                $finalOut = Select-SaveFileDialog -Title (Msg "SelectSaveDest") -InitialDirectory $DOWNLOADS_DIR -DefaultFileName "vod_${vodId}_with_chat.mp4" -FallbackPath $defaultOut
                $workDir  = Split-Path -Path $finalOut -Parent

                $chatFiles = Invoke-ChatRenderAndMerge -VodId $vodId -VideoFile $existingVideo -FinalOutput $finalOut -WorkDir $workDir -CheckSync $true -VodUrl $vodUrl -Unattended $false
                if ($chatFiles) {
                    if ($hasSleep) {
                        Invoke-SleepCountdown -SleepMinutes $sleepMinutes
                    } else {
                        $del = Read-Host (Msg "DeleteChatTemp")
                        if ($del -match '^[YySs]$') {
                            Remove-Item $chatFiles.ChatJson, $chatFiles.ChatVideo -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                break
            }

            "5" {
                if (-not (Assert-RequiredTools @("CLI"))) { break }
                $act = Msg "ActChatOnly"
                Write-StepProgress -Activity $act -Status (Msg "EnterVodOnly") -Percent 0
                Clear-StepProgress $act
                $vodRaw = Read-Host (Msg "EnterVodOnly")
                $parsed = Parse-Target $vodRaw
                if (-not $parsed -or $parsed.Type -ne "VOD") {
                    Write-Host ("[ERROR] " + (Msg "InvalidVod")) -ForegroundColor Red
                    break
                }
                $vodId = $parsed.Value

                Write-Host (Msg "SelectSaveDest") -ForegroundColor Yellow
                $defaultChatOut = Join-Path $DOWNLOADS_DIR "chat_${vodId}.json"
                $chatOut = Select-SaveFileDialog `
                    -Title (Msg "SelectSaveDest") `
                    -Filter "Twitch Chat JSON (*.json)|*.json|Text Chat (*.txt)|*.txt|HTML Chat (*.html)|*.html|All Files (*.*)|*.*" `
                    -DefaultExt "json" `
                    -InitialDirectory $DOWNLOADS_DIR `
                    -DefaultFileName "chat_${vodId}.json" `
                    -FallbackPath $defaultChatOut

                [void](Invoke-ChatDownloadOnly -VodId $vodId -OutputPath $chatOut)
                break
            }

            { $_ -in @("1", "2") } {
                $includeChat = ($choice -eq "2")
                $reqTools = if ($includeChat) { @("CLI", "YtDlp", "FFmpeg", "FFprobe") } else { @("CLI", "YtDlp", "FFmpeg") }
                if (-not (Assert-RequiredTools $reqTools)) { break }

                $act = Msg "ActVodFlow"
                Write-StepProgress -Activity $act -Status (Msg "EnterTarget") -Percent 0
                Clear-StepProgress $act

                Write-Host (Msg "SelectDestFolder") -ForegroundColor Yellow
                $chosenDest = Select-FolderDialog -Description (Msg "SelectDestFolder") -InitialDirectory $DEST_DIR -FallbackPath $DEST_DIR
                if (-not [string]::IsNullOrWhiteSpace($chosenDest)) {
                    $DEST_DIR = $chosenDest
                    New-Item -ItemType Directory -Force -Path $DEST_DIR | Out-Null
                }

                $targetRaw = Read-Host (Msg "EnterTarget")
                $parsed = Parse-Target $targetRaw
                if (-not $parsed) {
                    Write-Host ("[ERROR] " + (Msg "ParseError")) -ForegroundColor Red
                    break
                }

                $mode        = $null
                $vodId       = $null
                $vodFile     = $null
                $chunkDir    = $null
                $liveChannel = $null

                if ($parsed.Type -eq "CHANNEL") {
                    $ch = $parsed.Value
                    Write-StepProgress -Activity $act -Status (Fmt "CheckingLive" @($ch)) -Percent 10
                    Clear-StepProgress $act
                    $ytdlp = Get-ToolBinary "YtDlp"
                    $liveStatus = (& $ytdlp --print is_live "https://www.twitch.tv/$ch" 2>$null | Out-String).Trim()

                    if ($liveStatus -match 'True') {
                        $mode        = "LIVE_TS"
                        $liveChannel = $ch
                    } else {
                        Write-Host (Fmt "NotLiveFallback" @($ch)) -ForegroundColor Yellow
                        $fallback = Read-Host ""
                        if ([string]::IsNullOrWhiteSpace($fallback)) { break }
                        $parsed = Parse-Target $fallback
                        if (-not $parsed -or $parsed.Type -ne "VOD") {
                            Write-Host ("[ERROR] " + (Msg "InvalidVod")) -ForegroundColor Red
                            break
                        }
                    }
                }

                if ($parsed.Type -eq "VOD") {
                    $mode    = "VOD_CLI"
                    $vodId   = $parsed.Value
                    $vodFile = Join-Path $DEST_DIR "vod_$vodId.mp4"
                }

                # --- PHASE 1: DOWNLOAD ---
                if ($mode -eq "LIVE_TS") {
                    $cap = Invoke-LiveTsDownloadOnly -Channel $liveChannel -DestDir $DEST_DIR
                    if (-not $cap) { break }
                    $vodId    = $cap.VodId
                    $vodFile  = $cap.MergedFile
                    $chunkDir = $cap.ChunkDir
                } elseif ($mode -eq "VOD_CLI") {
                    Write-StepProgress -Activity $act -Status (Fmt "DownloadingVod" @($vodId)) -Percent 25
                    Clear-StepProgress $act
                    $cli = Get-ToolBinary "CLI"
                    & $cli videodownload --id $vodId -o $vodFile
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host ("[ERROR] " + (Fmt "DownloadVodErr" @($vodId))) -ForegroundColor Red
                        break
                    }
                    $dlPct = if ($includeChat) { 45 } else { 85 }
                    Write-StepProgress -Activity $act -Status (Fmt "VideoReady" @($vodFile)) -Percent $dlPct
                    Clear-StepProgress $act
                }

                # --- SLEEP AFTER DOWNLOAD ---
                if ($hasSleep) {
                    if ($mode -eq "VOD_CLI" -and (-not $includeChat)) {
                        Write-StepProgress -Activity $act -Status (Fmt "VideoReady" @($vodFile)) -Percent 100
                        Write-Host (Fmt "VideoReady" @($vodFile)) -ForegroundColor Green
                        Invoke-SleepCountdown -SleepMinutes $sleepMinutes
                        break
                    }

                    $nextDesc = if ($mode -eq "LIVE_TS") {
                        "merging .ts chunks" + $(if ($includeChat) { " + chat" } else { "" })
                    } else {
                        "chat download + render"
                    }
                    $shouldContinue = Invoke-SleepAndAskContinue -SleepMinutes $sleepMinutes -NextActionLabel $nextDesc
                    if (-not $shouldContinue) {
                        Write-Host (Fmt "StoppedAfterSleep" @($DEST_DIR)) -ForegroundColor Yellow
                        break
                    }
                }

                # --- PHASE 2: MERGE / CHAT RENDER ---
                if ($mode -eq "LIVE_TS") {
                    $mergedOk = Join-TsFiles -tsDir $chunkDir -outputFile $vodFile
                    if (-not $mergedOk) { break }
                }

                $chatFiles = $null
                if ($includeChat) {
                    $finalOut  = Join-Path $DEST_DIR "vod_${vodId}_with_chat.mp4"
                    $chatFiles = Invoke-ChatRenderAndMerge -VodId $vodId -VideoFile $vodFile -FinalOutput $finalOut -WorkDir $DEST_DIR -CheckSync $false -Unattended $hasSleep
                } else {
                    Write-StepProgress -Activity $act -Status (Fmt "VideoReady" @($vodFile)) -Percent 100
                    Write-Host (Fmt "VideoReady" @($vodFile)) -ForegroundColor Green
                }

                if (-not $hasSleep) {
                    $cleanup = Read-Host ("`n" + (Msg "CleanupPrompt"))
                    if ($cleanup -match '^[YySs]$') {
                        if ($chunkDir -and (Test-Path $chunkDir)) { Remove-Item $chunkDir -Recurse -Force -ErrorAction SilentlyContinue }
                        if ($includeChat -and $vodFile -and (Test-Path $vodFile)) { Remove-Item $vodFile -Force -ErrorAction SilentlyContinue }
                        if ($chatFiles) {
                            Remove-Item $chatFiles.ChatJson, $chatFiles.ChatVideo -Force -ErrorAction SilentlyContinue
                        }
                        Write-Host (Msg "CleanupDone") -ForegroundColor Yellow
                    }
                }
                break
            }
        }
    }

    if (-not (Invoke-AfterTaskPrompt)) {
        break
    }
}