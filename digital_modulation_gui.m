function digital_modulation_gui()
% =========================================================================
%  数字通信全栈可视化系统  (含 AWGN / 瑞利 / 莱斯 衰落信道 + OFDM)
%  MATLAB R2015a 兼容
% =========================================================================

    %% ---------------- 全局变量 ----------------
    currentMod = 'BPSK';
    currentData = [];  currentCarrier = [];
    currentModSignal = [];  currentT = [];
    currentBB = [];  currentBB_Rx = [];
    currentRxBits = [];
    currentChannelInfo = struct();

    %% ---------------- 主窗口 ----------------
    fig = figure('Name', 'Digital Communication Full-Stack Visualizer', ...
        'NumberTitle', 'off', 'Position', [10 10 1650 900], ...
        'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'on', ...
        'Color', [0.94 0.94 0.94]);

    %% ---------------- Input Signal 面板 ----------------
    pnlIn = uipanel('Parent', fig, 'Title', 'Input Signal', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.01 0.66 0.17 0.33]);

    uicontrol('Parent', pnlIn, 'Style', 'text', 'String', 'Amp Carrier1', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'Position', [0.04 0.88 0.42 0.06]);
    h_amp1 = uicontrol('Parent', pnlIn, 'Style', 'edit', 'String', '1', ...
        'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'w', ...
        'Position', [0.04 0.79 0.42 0.08]);

    uicontrol('Parent', pnlIn, 'Style', 'text', 'String', 'Amp Carrier2', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'Position', [0.53 0.88 0.42 0.06]);
    h_amp2 = uicontrol('Parent', pnlIn, 'Style', 'edit', 'String', '2', ...
        'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'w', ...
        'Position', [0.53 0.79 0.42 0.08]);

    uicontrol('Parent', pnlIn, 'Style', 'text', 'String', 'Freq Carrier1', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'Position', [0.04 0.68 0.42 0.06]);
    h_freq1 = uicontrol('Parent', pnlIn, 'Style', 'edit', 'String', '1', ...
        'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'w', ...
        'Position', [0.04 0.59 0.42 0.08]);

    uicontrol('Parent', pnlIn, 'Style', 'text', 'String', 'Freq Carrier2', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'Position', [0.53 0.68 0.42 0.06]);
    % ★ FSK 两个载波需要频率差，默认改为 2
    h_freq2 = uicontrol('Parent', pnlIn, 'Style', 'edit', 'String', '2', ...
        'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'w', ...
        'Position', [0.53 0.59 0.42 0.08]);

    uicontrol('Parent', pnlIn, 'Style', 'text', 'String', 'SNR / EbN0 (dB)', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'Position', [0.04 0.48 0.90 0.06]);
    h_snr = uicontrol('Parent', pnlIn, 'Style', 'edit', 'String', '10', ...
        'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'w', ...
        'Position', [0.04 0.39 0.90 0.08]);

    uicontrol('Parent', pnlIn, 'Style', 'text', 'String', 'Digital Data', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'Position', [0.04 0.28 0.90 0.06]);
    h_data = uicontrol('Parent', pnlIn, 'Style', 'edit', ...
        'String', '1 0 1 1 0 1 0 0 1 0 1 1 1 0 0 1 0 1 1 1 0 1 1 1', ...
        'Units', 'normalized', 'FontSize', 8, 'BackgroundColor', 'w', ...
        'Position', [0.04 0.08 0.90 0.16]);

    %% ---------------- Coding Options 面板 ----------------
    pnlCode = uipanel('Parent', fig, 'Title', 'Coding Options', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.01 0.32 0.17 0.33]);

    h_useConv = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'Conv (2,1,7) + Viterbi', 'Value', 1, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.92 0.90 0.07]);

    h_useRS = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'RS(15,11)', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.83 0.90 0.07]);

    h_useHam = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'Hamming (7,4)', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.74 0.90 0.07]);

    h_useBCH = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'BCH(15,7)', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.65 0.90 0.07]);

    h_useCRC = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'CRC-8', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.56 0.90 0.07]);

    h_useLDPC = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'LDPC (8,4)', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.47 0.90 0.07]);

    h_useHuff = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'Huffman', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.38 0.90 0.07]);

    h_useHDB3 = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'HDB3 线路编码', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.29 0.90 0.07]);

    h_useSRRC = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'SRRC (α=0.35)', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.20 0.90 0.07]);

    h_useCostas = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'Costas 载波同步', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.11 0.90 0.07]);

    h_useGardner = uicontrol('Parent', pnlCode, 'Style', 'checkbox', ...
        'String', 'Gardner 位同步', 'Value', 0, ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlCode, 'BackgroundColor'), ...
        'Position', [0.05 0.02 0.90 0.07]);

    %% ---------------- ★ Channel Model 面板 ----------------
    pnlChan = uipanel('Parent', fig, 'Title', 'Channel Model', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.01 0.16 0.17 0.15]);

    uicontrol('Parent', pnlChan, 'Style', 'text', 'String', 'Channel Type:', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlChan, 'BackgroundColor'), ...
        'Position', [0.05 0.78 0.90 0.16]);

    h_chanModel = uicontrol('Parent', pnlChan, 'Style', 'popupmenu', ...
        'String', {'AWGN (理想加性高斯)', 'Rayleigh (瑞利衰落)', 'Rician (莱斯衰落)'}, ...
        'Value', 1, ...
        'Units', 'normalized', 'FontSize', 8, 'BackgroundColor', 'w', ...
        'Position', [0.05 0.55 0.90 0.22], ...
        'Callback', @(s,e) onChannelModelChange());

    uicontrol('Parent', pnlChan, 'Style', 'text', 'String', 'K-factor(dB)', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlChan, 'BackgroundColor'), ...
        'Position', [0.05 0.32 0.55 0.16]);
    h_kFactor = uicontrol('Parent', pnlChan, 'Style', 'edit', 'String', '10', ...
        'Units', 'normalized', 'FontSize', 8, 'BackgroundColor', [0.85 0.85 0.85], ...
        'Enable', 'off', ...
        'Position', [0.62 0.30 0.33 0.20]);

    uicontrol('Parent', pnlChan, 'Style', 'text', 'String', 'fd (Hz)', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 8, ...
        'BackgroundColor', get(pnlChan, 'BackgroundColor'), ...
        'Position', [0.05 0.08 0.55 0.16]);
    h_doppler = uicontrol('Parent', pnlChan, 'Style', 'edit', 'String', '100', ...
        'Units', 'normalized', 'FontSize', 8, 'BackgroundColor', 'w', ...
        'Position', [0.62 0.06 0.33 0.20]);

    %% ---------------- Run 面板 ----------------
    pnlRun = uipanel('Parent', fig, 'Title', 'Run', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.01 0.01 0.17 0.14]);

    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'BPSK', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.02 0.72 0.30 0.22], 'Callback', @(s,e) runModulation('BPSK'));
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'DPSK', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.34 0.72 0.30 0.22], 'Callback', @(s,e) runModulation('DPSK'));
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'QPSK', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.66 0.72 0.30 0.22], 'Callback', @(s,e) runModulation('QPSK'));
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'ASK', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.02 0.48 0.30 0.22], 'Callback', @(s,e) runModulation('ASK'));
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'FSK', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.34 0.48 0.30 0.22], 'Callback', @(s,e) runModulation('FSK'));
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'QAM', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.66 0.48 0.30 0.22], 'Callback', @(s,e) runModulation('QAM'));

    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'Show Fig', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.02 0.24 0.30 0.20], 'Callback', @(s,e) showCurrentFigure());
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'Coding', ...
        'Units', 'normalized', 'FontSize', 8, 'BackgroundColor', [0.75 0.90 0.75], ...
        'Position', [0.34 0.24 0.30 0.20], 'Callback', @(s,e) showCodingViewer());
    % ★ OFDM 按钮：打开完整的 OFDM 调制/解调窗口
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'OFDM', ...
        'Units', 'normalized', 'FontSize', 8, 'BackgroundColor', [0.7 0.85 1.0], ...
        'Position', [0.66 0.24 0.30 0.20], 'Callback', @(s,e) showOFDMModulator());

    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'Conv.', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.02 0.02 0.30 0.18], 'Callback', @(s,e) showConvCodeViewer());
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'Channel', ...
        'Units', 'normalized', 'FontSize', 8, 'BackgroundColor', [1.0 0.88 0.7], ...
        'Position', [0.34 0.02 0.30 0.18], 'Callback', @(s,e) showChannelViewer());
    uicontrol('Parent', pnlRun, 'Style', 'pushbutton', 'String', 'Close', ...
        'Units', 'normalized', 'FontSize', 8, ...
        'Position', [0.66 0.02 0.30 0.18], 'Callback', @(s,e) close(fig));

    %% ---------------- 绘图区 ----------------
    ax1 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.19 0.74 0.45 0.20], 'FontSize', 8);
    ax2 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.19 0.50 0.45 0.20], 'FontSize', 8);
    ax3 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.19 0.26 0.45 0.20], 'FontSize', 8);

    axSpec  = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.66 0.72 0.33 0.22], 'FontSize', 8);
    axConst = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.66 0.44 0.33 0.24], 'FontSize', 8);
    axBER   = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.66 0.10 0.33 0.28], 'FontSize', 8);

    h_title = uicontrol('Parent', fig, 'Style', 'text', ...
        'String', 'Binary phase-shift keying (BPSK)', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.94 0.94 0.94], ...
        'Position', [0.19 0.955 0.80 0.03]);

    %% ---------------- Demodulation 结果面板 ----------------
    pnlDemod = uipanel('Parent', fig, 'Title', 'Demodulation Result', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.19 0.01 0.45 0.21]);

    uicontrol('Parent', pnlDemod, 'Style', 'text', ...
        'String', 'Demodulated Bits (Rx):', ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 9, ...
        'BackgroundColor', get(pnlDemod, 'BackgroundColor'), ...
        'Position', [0.02 0.86 0.45 0.10]);

    h_demodBits = uicontrol('Parent', pnlDemod, 'Style', 'edit', ...
        'String', '', 'Units', 'normalized', 'FontSize', 8, ...
        'HorizontalAlignment', 'left', 'Max', 2, 'Min', 0, ...
        'Enable', 'inactive', 'BackgroundColor', [1 1 1], ...
        'Position', [0.02 0.44 0.96 0.40]);

    h_demodStat1 = uicontrol('Parent', pnlDemod, 'Style', 'text', ...
        'String', '', 'Units', 'normalized', 'FontSize', 9, ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', get(pnlDemod, 'BackgroundColor'), ...
        'Position', [0.02 0.24 0.96 0.16]);

    h_demodStat2 = uicontrol('Parent', pnlDemod, 'Style', 'text', ...
        'String', '', 'Units', 'normalized', 'FontSize', 8, ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', get(pnlDemod, 'BackgroundColor'), ...
        'Position', [0.02 0.03 0.96 0.18]);

    %% =====================================================================
    %                     ★ 信道模型回调
    %  =====================================================================
    function onChannelModelChange()
        v = get(h_chanModel, 'Value');
        if v == 3   % Rician
            set(h_kFactor, 'Enable', 'on', 'BackgroundColor', 'w');
        else
            set(h_kFactor, 'Enable', 'off', 'BackgroundColor', [0.85 0.85 0.85]);
        end
        runModulation(currentMod);
    end

    %% =====================================================================
    %                     ★ 信道模型核心 (AWGN / Rayleigh / Rician)
    %  =====================================================================
    function [rxBB, chInfo] = applyChannel(txBB, snr, modelType, kdB, fd, spb)
        N = length(txBB);
        sigPow = mean(abs(txBB).^2);
        if sigPow <= 0, sigPow = 1; end
        noisePow = sigPow / 10^(snr/10);

        switch modelType
            case 1  % ============ AWGN ============
                h = ones(1, N);
                chInfo.type      = 'AWGN';
                chInfo.typeCn    = '加性高斯白噪声';
                chInfo.description = '理想 AWGN 信道：y = x + n';
                chInfo.Kfactor_dB = NaN;

            case 2  % ============ Rayleigh ============
                nPaths = 8;
                h = zeros(1, N);
                for p = 1:nPaths
                    phi  = 2*pi*rand;
                    phase_inc = 2*pi*fd/spb * cos(2*pi*rand);
                    h = h + exp(1j*(phi + phase_inc*(0:N-1)));
                end
                h = h / sqrt(nPaths);
                chInfo.type      = 'Rayleigh';
                chInfo.typeCn    = '瑞利衰落 (NLOS)';
                chInfo.description = '瑞利衰落：无视距分量, |h|~Rayleigh';
                chInfo.Kfactor_dB = -inf;

            case 3  % ============ Rician ============
                K = 10^(kdB/10);
                losMag  = sqrt(K/(K+1));
                scatMag = sqrt(1/(K+1));
                nPaths = 8;
                scat = zeros(1, N);
                for p = 1:nPaths
                    phi = 2*pi*rand;
                    phase_inc = 2*pi*fd/spb * cos(2*pi*rand);
                    scat = scat + exp(1j*(phi + phase_inc*(0:N-1)));
                end
                scat = scat / sqrt(nPaths);
                theta0 = pi/4;
                los = losMag * exp(1j*2*pi*fd/spb*cos(theta0)*(0:N-1));
                h = los + scatMag * scat;
                chInfo.type      = 'Rician';
                chInfo.typeCn    = '莱斯衰落 (LOS + 散射)';
                chInfo.description = sprintf('莱斯衰落: K = %.1f dB, LOS + NLOS', kdB);
                chInfo.Kfactor_dB = kdB;

            otherwise
                h = ones(1, N);
                chInfo.type      = 'AWGN';
                chInfo.typeCn    = '加性高斯白噪声';
                chInfo.description = '理想 AWGN 信道';
                chInfo.Kfactor_dB = NaN;
        end

        noise = sqrt(noisePow/2) * (randn(1, N) + 1j*randn(1, N));
        rxBB = h .* txBB + noise;

        chInfo.h         = h;
        chInfo.noise     = noise;
        chInfo.noisePow  = noisePow;
        chInfo.sigPow    = sigPow;
        chInfo.snr       = snr;
        chInfo.fd        = fd;
        chInfo.spb       = spb;
        chInfo.modelType = modelType;
    end

    %% =====================================================================
    %                            核心调制 + 解调
    %  =====================================================================
    function runModulation(modType)
        currentMod = modType;
        f1 = str2double(get(h_freq1, 'String')); if isnan(f1), f1 = 1; end
        f2 = str2double(get(h_freq2, 'String')); if isnan(f2), f2 = 2; end
        amp1 = str2double(get(h_amp1, 'String')); if isnan(amp1), amp1 = 1; end
        amp2 = str2double(get(h_amp2, 'String')); if isnan(amp2), amp2 = 2; end
        snr = str2double(get(h_snr, 'String')); if isnan(snr), snr = 10; end
        kdB = str2double(get(h_kFactor, 'String')); if isnan(kdB), kdB = 10; end
        fd  = str2double(get(h_doppler, 'String')); if isnan(fd), fd = 100; end
        modelType = get(h_chanModel, 'Value');

        dataStr = get(h_data, 'String');
        dataStr = strrep(dataStr, ',', ' ');
        dataVec = sscanf(dataStr, '%d')';
        if isempty(dataVec)
            dataVec = [0 0 1 0 1 0 1 1 0 0 1 1 1 0 0 1 0 1 1 1 0 1 1 1];
        end

        % ---- 编码链 ----
        if get(h_useHuff,'Value'), dataVec = huffman_encode(dataVec); end
        if get(h_useRS,  'Value'), dataVec = rs_encode_15_11(dataVec); end
        if get(h_useBCH, 'Value'), dataVec = bch_encode_15_7(dataVec); end
        if get(h_useHam, 'Value'), dataVec = ham74_encode(dataVec); end
        if get(h_useConv,'Value'), dataVec = conv_encode_217(dataVec); end
        if get(h_useCRC, 'Value'), dataVec = crc8_encode(dataVec); end
        if get(h_useLDPC,'Value'), dataVec = ldpc_encode_8_4(dataVec); end

        N = length(dataVec);
        spb = 100;
        t = 1 : N*spb;
        dExp = kron(dataVec, ones(1, spb));

        % ★ FSK 要求两个载波频率不同，否则自动修正
        if strcmp(modType, 'FSK') && f1 == f2
            f2 = f1 + 1;
            set(h_freq2, 'String', num2str(f2));
        end

        wc1 = 2*pi*f1 / spb; wc2 = 2*pi*f2 / spb;
        c1f = sin(wc1 * t); c2f = sin(wc2 * t);
        modSignal = zeros(1, length(t)); bb = [];

        switch modType
            case 'BPSK'
                bb = exp(1j*pi*dataVec);
                modSignal = c1f .* (2*dExp - 1);
                currentCarrier = c1f;
                h_title.String = 'BPSK';

            case 'ASK'
                bb = (dataVec + 1) / 2;
                ampVec = dExp * amp2 + (1 - dExp) * amp1;
                modSignal = ampVec .* c1f;
                currentCarrier = c1f;
                h_title.String = 'ASK';

            case 'FSK'
                % ★ 逐采样生成相位连续的 FSK 射频信号
                currentCarrier = struct('c1', c1f, 'c2', c2f);
                phase = 0;
                for i = 1:length(t)
                    if dExp(i) == 1
                        freq = f1;
                    else
                        freq = f2;
                    end
                    modSignal(i) = sin(phase);
                    phase = phase + 2*pi*freq/spb;
                end
                % ★ 直接把射频信号交给信道加噪（信道对 FSK 才生效）
                bb = modSignal;
                h_title.String = 'FSK';

            case 'DPSK'
                diffData = zeros(1, N); diffData(1) = dataVec(1);
                for i = 2:N, diffData(i) = mod(dataVec(i) + diffData(i-1), 2); end
                bb = exp(1j*pi*diffData);
                dExp2 = kron(diffData, ones(1, spb));
                modSignal = c1f .* (2*dExp2 - 1);
                currentCarrier = c1f;
                h_title.String = 'DPSK';

            case 'QPSK'
                Ns = floor(N/2); b1 = dataVec(1:2:2*Ns); b2 = dataVec(2:2:2*Ns);
                Is = zeros(1, Ns); Qs = zeros(1, Ns);
                for k = 1:Ns
                    if b1(k)==0 && b2(k)==0, Is(k)=1;
                    elseif b1(k)==0 && b2(k)==1, Qs(k)=1;
                    elseif b1(k)==1 && b2(k)==1, Is(k)=-1;
                    else, Qs(k)=-1; end
                end
                bb = Is + 1j*Qs;
                Ie = kron(Is, ones(1, 2*spb)); Qe = kron(Qs, ones(1, 2*spb));
                L = length(t);
                if length(Ie) < L
                    Ie = [Ie, zeros(1, L-length(Ie))];
                    Qe = [Qe, zeros(1, L-length(Qe))];
                end
                modSignal = Ie(1:L) .* cos(wc1*t) - Qe(1:L) .* sin(wc1*t);
                currentCarrier = c1f;
                h_title.String = 'QPSK';

            case 'QAM'
                Ns = floor(N/3);
                b1 = dataVec(1:3:3*Ns); b2 = dataVec(2:3:3*Ns); b3 = dataVec(3:3:3*Ns);
                idx = b1*4 + b2*2 + b3;
                Itab = [-3 -1 1 3 -3 -1 1 3]; Qtab = [-1 -1 -1 -1 1 1 1 1];
                Is = Itab(idx+1)/3; Qs = Qtab(idx+1)/3;
                bb = Is + 1j*Qs;
                Ie = kron(Is, ones(1, 3*spb)); Qe = kron(Qs, ones(1, 3*spb));
                L = length(t);
                if length(Ie) < L
                    Ie = [Ie, zeros(1, L-length(Ie))];
                    Qe = [Qe, zeros(1, L-length(Qe))];
                end
                modSignal = Ie(1:L) .* cos(wc1*t) - Qe(1:L) .* sin(wc1*t);
                currentCarrier = c1f;
                h_title.String = '8-QAM';
        end

        % ================= ★ 通过信道模型 =================
        if ~isempty(bb)
            [currentBB_Rx, currentChannelInfo] = applyChannel(bb, snr, modelType, kdB, fd, spb);
        else
            currentBB_Rx = [];
            currentChannelInfo = struct();
        end

        currentData = dataVec;
        currentModSignal = modSignal;
        currentT = t;
        currentBB = bb;

        % ================= 解调 =================
        [rxBits, berMod, errCnt] = demodulateSignal(...
            modType, currentBB_Rx, modSignal, spb, c1f, c2f, N, dataVec);
        currentRxBits = rxBits;

        % ---- 更新解调结果面板 ----
        if ~isempty(rxBits)
            strRx = char(48 + rxBits);
            if length(strRx) > 900
                strRx = [strRx(1:900) ' ...'];
            end
            set(h_demodBits, 'String', strRx);
            Lcmp = min(length(rxBits), length(dataVec));
            set(h_demodStat1, 'String', sprintf(...
                '%s @ %s  |  Tx: %d  Rx: %d  Err: %d  BER: %.3e', ...
                modType, currentChannelInfo.type, length(dataVec), length(rxBits), errCnt, berMod));
            strTx = char(48 + dataVec(1:min(Lcmp, 300)));
            set(h_demodStat2, 'String', sprintf('Tx (reference): %s', strTx));
        else
            set(h_demodBits, 'String', '(no data)');
            set(h_demodStat1, 'String', '');
            set(h_demodStat2, 'String', '');
        end

        updatePlots();
    end

    %% =====================================================================
    %                  解调器 (支持全部调制方式)
    %  =====================================================================
    function [rxBits, berMod, errCnt] = demodulateSignal(...
            modType, bbRx, modSig, spb, c1f, c2f, N, txBits)
        rxBits = [];
        switch modType
            case 'BPSK'
                if ~isempty(bbRx)
                    rxBits = double(real(bbRx) < 0);
                end

            case 'ASK'
                if ~isempty(bbRx)
                    rxBits = double(real(bbRx) > 0.75);
                end

            case 'FSK'
                % ★ 用经过信道加噪后的 bbRx 做相关检测
                if ~isempty(bbRx)
                    rxBits = zeros(1, N);
                    sig   = real(bbRx);
                    Lsig  = length(sig);
                    for i = 1:N
                        a = (i-1)*spb + 1;
                        b = min(i*spb, Lsig);
                        if a > b, break; end
                        seg = sig(a:b);
                        s1  = c1f(a:b);
                        s2  = c2f(a:b);
                        e1  = abs(sum(seg .* s1));
                        e2  = abs(sum(seg .* s2));
                        rxBits(i) = double(e1 > e2);
                    end
                end

            case 'DPSK'
                if ~isempty(bbRx)
                    diffRx = double(real(bbRx) < 0);
                    rxBits = zeros(1, length(diffRx));
                    rxBits(1) = diffRx(1);
                    for i = 2:length(diffRx)
                        rxBits(i) = mod(diffRx(i) + diffRx(i-1), 2);
                    end
                end

            case 'QPSK'
                if ~isempty(bbRx)
                    Ns   = floor(N/2);
                    refs = [1, 1j, -1, -1j];
                    bmap = [0 0; 0 1; 1 1; 1 0];
                    rxBits = zeros(1, 2*Ns);
                    for k = 1:min(Ns, length(bbRx))
                        [~, idx] = min(abs(bbRx(k) - refs));
                        rxBits(2*k-1) = bmap(idx, 1);
                        rxBits(2*k)   = bmap(idx, 2);
                    end
                end

            case 'QAM'
                if ~isempty(bbRx)
                    Ns   = floor(N/3);
                    Itab = [-3 -1 1 3 -3 -1 1 3];
                    Qtab = [-1 -1 -1 -1 1 1 1 1];
                    refs = (Itab + 1j*Qtab)/3;
                    rxBits = zeros(1, 3*Ns);
                    for k = 1:min(Ns, length(bbRx))
                        [~, idx] = min(abs(bbRx(k) - refs));
                        idx = idx - 1;
                        rxBits(3*k-2) = floor(idx/4);
                        rxBits(3*k-1) = mod(floor(idx/2), 2);
                        rxBits(3*k)   = mod(idx, 2);
                    end
                end
        end

        if isempty(rxBits)
            berMod = NaN; errCnt = NaN;
        else
            L = min(length(rxBits), length(txBits));
            errCnt = sum(rxBits(1:L) ~= txBits(1:L));
            if L > 0
                berMod = errCnt / L;
            else
                berMod = NaN;
            end
        end
    end

    %% =====================================================================
    %                    基础编码 (Conv / RS)
    %  =====================================================================
    function encoded = conv_encode_217(data)
        g0 = [1 1 1 1 0 0 1]; g1 = [1 0 1 1 0 1 1]; K = 7;
        data = data(:)'; N = length(data);
        dataP = [data, zeros(1, K-1)];
        reg = zeros(1, K);
        encoded = zeros(1, 2*(N+K-1));
        for i = 1:length(dataP)
            reg = [dataP(i), reg(1:K-1)];
            o0 = mod(sum(reg .* g0), 2);
            o1 = mod(sum(reg .* g1), 2);
            encoded(2*i-1) = o0; encoded(2*i) = o1;
        end
    end

    function decoded = viterbi_decode_217(rx, N_orig)
        g0 = [1 1 1 1 0 0 1]; g1 = [1 0 1 1 0 1 1]; K = 7;
        NS = 2^(K-1);
        nxt = zeros(NS, 2); out = zeros(NS, 2);
        for s = 0:NS-1
            sb = bitget(s, K-1:-1:1);
            for inp = 0:1
                reg = [inp, sb];
                o0 = mod(sum(reg .* g0), 2);
                o1 = mod(sum(reg .* g1), 2);
                out(s+1, inp+1) = o0*2 + o1;
                nsb = [inp, sb(1:K-2)]; ns = 0;
                for j = 1:K-1, ns = ns * 2 + nsb(j); end
                nxt(s+1, inp+1) = ns;
            end
        end
        L = floor(length(rx) / 2);
        PM = inf(NS, L+1); PM(1,1) = 0;
        si = zeros(NS, L+1); sp = zeros(NS, L+1);
        for t = 1:L
            rsym = rx(2*t-1)*2 + rx(2*t);
            for s = 1:NS
                if PM(s,t) == inf, continue; end
                for inp = 1:2
                    ns = nxt(s,inp) + 1;
                    d = bitxor(out(s,inp), rsym);
                    bm = sum(bitget(d, [1 2]));
                    if PM(s,t) + bm < PM(ns,t+1)
                        PM(ns,t+1) = PM(s,t) + bm;
                        si(ns,t+1) = inp - 1; sp(ns,t+1) = s;
                    end
                end
            end
        end
        [~, cur] = min(PM(:,L+1));
        path = zeros(1, L);
        for t = L:-1:1
            path(t) = si(cur, t+1);
            cur = sp(cur, t+1);
        end
        decoded = path(1:min(N_orig, length(path)));
    end

    function encoded = rs_encode_15_11(data)
        N = length(data);
        pad = mod(11 - mod(N, 11), 11);
        dP = [data, zeros(1, pad)];
        nb = length(dP) / 11;
        encoded = zeros(1, nb * 15);
        for b = 1:nb
            msg = dP((b-1)*11+1 : b*11);
            p1 = mod(sum(msg(1:2:end)), 2);
            p2 = mod(sum(msg(2:2:end)), 2);
            p3 = mod(sum(msg(1:3:end)), 2);
            p4 = mod(sum(msg) + 1, 2);
            encoded((b-1)*15+1 : b*15) = [msg, p1, p2, p3, p4];
        end
    end

    %% =====================================================================
    %                Hamming (7,4) 编解码
    %  =====================================================================
    function encoded = ham74_encode(data)
        N = length(data);
        pad = mod(4 - mod(N,4), 4);
        d = [data, zeros(1, pad)];
        nb = length(d)/4;
        encoded = zeros(1, nb*7);
        for b = 1:nb
            dd = d((b-1)*4+1:b*4);
            p1 = mod(dd(1)+dd(2)+dd(4), 2);
            p2 = mod(dd(1)+dd(3)+dd(4), 2);
            p4 = mod(dd(2)+dd(3)+dd(4), 2);
            encoded((b-1)*7+1:b*7) = [p1 p2 dd(1) p4 dd(2) dd(3) dd(4)];
        end
    end

    function decoded = ham74_decode(rx)
        N = length(rx);
        nb = floor(N/7);
        decoded = zeros(1, nb*4);
        H = [1 0 1 0 1 0 1; 0 1 1 0 0 1 1; 0 0 0 1 1 1 1];
        for b = 1:nb
            r = rx((b-1)*7+1:b*7);
            s = mod(H*r', 2);
            syn = s(1)*4 + s(2)*2 + s(3);
            if syn > 0 && syn <= 7
                r(syn) = mod(r(syn)+1, 2);
            end
            decoded((b-1)*4+1:b*4) = [r(3) r(5) r(6) r(7)];
        end
    end

    %% =====================================================================
    %                BCH (15,7) 编解码
    %  =====================================================================
    function encoded = bch_encode_15_7(data)
        poly = [1 1 1 0 1 0 0 0 1];
        N = length(data);
        pad = mod(7 - mod(N,7), 7);
        d = [data, zeros(1, pad)];
        nb = length(d)/7;
        encoded = zeros(1, nb*15);
        for b = 1:nb
            msg = d((b-1)*7+1:b*7);
            shifted = [msg, zeros(1, 8)];
            for i = 1:7
                if shifted(i) == 1
                    shifted(i:i+8) = mod(shifted(i:i+8) + poly, 2);
                end
            end
            parity = shifted(8:15);
            encoded((b-1)*15+1:b*15) = [msg, parity];
        end
    end

    function decoded = bch_decode_15_7(rx)
        N = length(rx);
        nb = floor(N/15);
        decoded = zeros(1, nb*7);
        poly = [1 1 1 0 1 0 0 0 1];
        for b = 1:nb
            r = rx((b-1)*15+1:b*15);
            tmp = r;
            for i = 1:7
                if tmp(i) == 1
                    tmp(i:i+8) = mod(tmp(i:i+8) + poly, 2);
                end
            end
            syn = sum(tmp(8:15));
            if syn > 0
                best = inf; bestPos = 0;
                for p = 1:15
                    rt = r; rt(p) = mod(rt(p)+1, 2);
                    tt = rt;
                    for i = 1:7
                        if tt(i) == 1
                            tt(i:i+8) = mod(tt(i:i+8) + poly, 2);
                        end
                    end
                    s2 = sum(tt(8:15));
                    if s2 < best, best = s2; bestPos = p; end
                end
                if bestPos > 0, r(bestPos) = mod(r(bestPos)+1, 2); end
            end
            decoded((b-1)*7+1:b*7) = r(1:7);
        end
    end

    %% =====================================================================
    %                CRC-8 编解码
    %  =====================================================================
    function encoded = crc8_encode(data)
        poly = [1 0 0 0 0 0 1 1 1];
        N = length(data);
        msg = [data, zeros(1, 8)];
        for i = 1:N
            if msg(i) == 1
                msg(i:i+8) = mod(msg(i:i+8) + poly, 2);
            end
        end
        encoded = [data, msg(N+1:N+8)];
    end

    function [decoded, errFlag] = crc8_check(rx)
        poly = [1 0 0 0 0 0 1 1 1];
        tmp = rx;
        N = length(rx);
        for i = 1:(N-8)
            if tmp(i) == 1
                tmp(i:i+8) = mod(tmp(i:i+8) + poly, 2);
            end
        end
        errFlag = any(tmp(N-7:N));
        decoded = rx(1:N-8);
    end

    %% =====================================================================
    %                LDPC (8,4) 简化实现
    %  =====================================================================
    function encoded = ldpc_encode_8_4(data)
        N = length(data);
        pad = mod(4 - mod(N,4), 4);
        d = [data, zeros(1, pad)];
        nb = length(d)/4;
        encoded = zeros(1, nb*8);
        for b = 1:nb
            m = d((b-1)*4+1:b*4);
            p1 = mod(m(1)+m(2)+m(3), 2);
            p2 = mod(m(1)+m(2)+m(4), 2);
            p3 = mod(m(1)+m(3)+m(4), 2);
            p4 = mod(m(2)+m(3)+m(4), 2);
            encoded((b-1)*8+1:b*8) = [m, p1, p2, p3, p4];
        end
    end

    function decoded = ldpc_decode_8_4(rx)
        N = length(rx);
        nb = floor(N/8);
        decoded = zeros(1, nb*4);
        H = [1 1 1 0 1 0 0 0;
             1 1 0 1 0 1 0 0;
             1 0 1 1 0 0 1 0;
             0 1 1 1 0 0 0 1];
        for b = 1:nb
            r = rx((b-1)*8+1:b*8);
            for iter = 1:5
                s = mod(H*r', 2);
                if all(s == 0), break; end
                flipCnt = H' * s;
                [~, idx] = max(flipCnt);
                r(idx) = mod(r(idx)+1, 2);
            end
            decoded((b-1)*4+1:b*4) = r(1:4);
        end
    end

    %% =====================================================================
    %                HDB3 线路编码
    %  =====================================================================
    function [hdb3, info] = hdb3_encode(data)
        N = length(data);
        hdb3 = zeros(1, N);
        lastPolarity = -1;
        zeroRun = 0;
        pulseCount = 0;
        info = struct();
        i = 1;
        while i <= N
            if data(i) == 1
                lastPolarity = -lastPolarity;
                hdb3(i) = lastPolarity;
                pulseCount = pulseCount + 1;
                zeroRun = 0;
                i = i + 1;
            else
                j = i;
                while j <= N && data(j) == 0, j = j + 1; end
                runLen = j - i;
                while runLen >= 4
                    if mod(pulseCount, 2) == 0
                        hdb3(i+3) = lastPolarity;
                        pulseCount = pulseCount + 1;
                    else
                        lastPolarity = -lastPolarity;
                        hdb3(i) = lastPolarity;
                        hdb3(i+3) = lastPolarity;
                        pulseCount = pulseCount + 2;
                    end
                    i = i + 4;
                    runLen = runLen - 4;
                end
                i = i + runLen;
                zeroRun = 0;
            end
        end
    end

    function decoded = hdb3_decode(hdb3)
        N = length(hdb3);
        decoded = zeros(1, N);
        for i = 1:N
            if hdb3(i) ~= 0
                decoded(i) = 1;
            end
        end
    end

    %% =====================================================================
    %                Huffman 编码
    %  =====================================================================
    function [encoded, dictInfo] = huffman_encode(data)
        N = length(data);
        pad = mod(4 - mod(N,4), 4);
        d = [data, zeros(1, pad)];
        nb = length(d) / 4;
        syms = zeros(1, nb);
        for k = 1:nb
            syms(k) = d((k-1)*4+1)*8 + d((k-1)*4+2)*4 + d((k-1)*4+3)*2 + d((k-1)*4+4);
        end
        us = unique(syms);
        freq = zeros(1, length(us));
        for k = 1:length(us)
            freq(k) = sum(syms == us(k));
        end
        try
            [dict, ~] = huffmandict(us, freq / sum(freq));
            encoded = huffmanenco(syms, dict);
            dictInfo = dict;
        catch
            encoded = data;
            dictInfo = [];
        end
        encoded = encoded(:)';
    end

    %% =====================================================================
    %              ★★★ Channel Viewer (信道可视化) ★★★
    %  =====================================================================
    function showChannelViewer()
        if isempty(currentBB)
            errordlg('Please run a modulation first!', 'Warning');
            return;
        end
        if ~isfield(currentChannelInfo, 'type')
            errordlg('No channel info. Re-run modulation.', 'Warning');
            return;
        end

        chInfo = currentChannelInfo;
        N = length(currentBB);

        figC = figure('Name', 'Channel Model Viewer', 'NumberTitle', 'off', ...
            'Position', [60 30 1400 850], 'Color', [1 1 1]);

        switch chInfo.modelType
            case 1
                chanColor = [0.85 0.95 0.85];
            case 2
                chanColor = [1.0 0.85 0.85];
            case 3
                chanColor = [1.0 0.95 0.75];
        end
        infoStr = sprintf(['Channel: %s (%s)  |  SNR = %.2f dB  |  Nsym = %d  ' ...
            '|  Noise Pwr = %.3e'], ...
            chInfo.typeCn, chInfo.type, chInfo.snr, N, chInfo.noisePow);
        uicontrol('Parent', figC, 'Style', 'text', 'String', infoStr, ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', chanColor, ...
            'Position', [0.02 0.955 0.96 0.035]);

        uicontrol('Parent', figC, 'Style', 'text', 'String', chInfo.description, ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95], ...
            'Position', [0.02 0.915 0.96 0.030]);

        subplot(2,3,1);
        stem(0:N-1, abs(chInfo.h), 'filled', 'MarkerSize', 3, ...
            'Color', [0.2 0.4 0.9]);
        hold on;
        plot(0:N-1, mean(abs(chInfo.h))*ones(1,N), 'r--', 'LineWidth', 1.0);
        hold off;
        title(sprintf('① Channel Magnitude |h|  (mean=%.3f)', mean(abs(chInfo.h))), ...
            'FontSize', 10);
        xlabel('Symbol Index'); ylabel('|h|'); grid on;

        subplot(2,3,2);
        plot(0:N-1, angle(chInfo.h)*180/pi, 'b', 'LineWidth', 1.2);
        title('② Channel Phase \angleh  (deg)', 'FontSize', 10);
        xlabel('Symbol Index'); ylabel('Phase (deg)'); grid on;

        subplot(2,3,3);
        Hf = fftshift(fft(chInfo.h));
        faxis = linspace(-0.5, 0.5, length(Hf));
        plot(faxis, 20*log10(abs(Hf) + eps), 'm', 'LineWidth', 1.2);
        hold on; plot([-0.5 0.5],[0 0], 'k--'); hold off;
        title('③ Channel Frequency Response |H(f)|', 'FontSize', 10);
        xlabel('Norm. Freq'); ylabel('|H| (dB)'); grid on;
        xlim([-0.5 0.5]);

        subplot(2,3,4);
        plot(real(currentBB), imag(currentBB), 'bo', 'MarkerSize', 7);
        hold on; plot([-1.5 1.5], [0 0], 'k:', [0 0], [-1.5 1.5], 'k:'); hold off;
        axis equal; grid on;
        xlim([-1.6 1.6]); ylim([-1.6 1.6]);
        title('④ Tx Symbols (Ideal)', 'FontSize', 10);
        xlabel('I'); ylabel('Q');

        subplot(2,3,5);
        plot(real(currentBB_Rx), imag(currentBB_Rx), 'r.', 'MarkerSize', 14);
        hold on; plot([-1.5 1.5], [0 0], 'k:', [0 0], [-1.5 1.5], 'k:'); hold off;
        axis equal; grid on;
        xlim([-1.6 1.6]); ylim([-1.6 1.6]);
        title('⑤ Rx Symbols (Faded + Noisy)', 'FontSize', 10);
        xlabel('I'); ylabel('Q');

        ax6 = subplot(2,3,6); cla(ax6); axis(ax6, [0 1 0 1]); axis(ax6, 'off');
        statsLines = {
            '信道模型统计 (Channel Statistics):', ...
            '─────────────────────────────', ...
            sprintf('信道类型: %s', chInfo.typeCn), ...
            sprintf('数学描述: %s', chInfo.description), ...
            sprintf('SNR (Eb/N0): %.2f dB', chInfo.snr), ...
            sprintf('信号功率: %.4f', chInfo.sigPow), ...
            sprintf('噪声功率: %.4f', chInfo.noisePow), ...
            sprintf('Doppler 频率: %.1f Hz', chInfo.fd), ...
            '', ...
            sprintf('|h| 均值: %.4f', mean(abs(chInfo.h))), ...
            sprintf('|h| 标准差: %.4f', std(abs(chInfo.h))), ...
            sprintf('|h| 最大值: %.4f', max(abs(chInfo.h))), ...
            sprintf('|h| 最小值: %.4f', min(abs(chInfo.h))), ...
            sprintf('相位均值: %.2f deg', mean(angle(chInfo.h))*180/pi)
        };
        if chInfo.modelType == 3
            statsLines{end+1} = '';
            statsLines{end+1} = sprintf('莱斯 K 因子: %.2f dB', chInfo.Kfactor_dB);
        elseif chInfo.modelType == 2
            statsLines{end+1} = '';
            statsLines{end+1} = '莱斯 K 因子: -inf (纯瑞利)';
        end
        text(0.02, 0.98, statsLines, 'Parent', ax6, ...
            'VerticalAlignment', 'top', 'FontSize', 8.5, 'FontName', 'FixedWidth');
        title('⑥ Channel Statistics', 'FontSize', 10);
    end

    %% =====================================================================
    %              Coding Viewer (综合编解码可视化)
    %  =====================================================================
    function showCodingViewer()
        dataStr = get(h_data, 'String');
        dataStr = strrep(dataStr, ',', ' ');
        orig = sscanf(dataStr, '%d')';
        if isempty(orig), errordlg('Input data!', 'Warning'); return; end
        snr = str2double(get(h_snr, 'String')); if isnan(snr), snr = 10; end

        N0 = length(orig);
        hEnc = ham74_encode(orig);
        hDec = ham74_decode(hEnc);
        cEnc = crc8_encode(orig);
        bEnc = bch_encode_15_7(orig);
        [hdb3, ~] = hdb3_encode(orig);
        lEnc = ldpc_encode_8_4(orig);
        [hufEnc, hufDict] = huffman_encode(orig);

        figC = figure('Name', 'Coding Viewer', 'NumberTitle', 'off', ...
            'Position', [40 30 1400 850], 'Color', [1 1 1]);

        infoStr = sprintf(['Original: %d bits  |  Hamming(7,4)->%d  |  ' ...
            'CRC-8->%d  |  BCH(15,7)->%d  |  LDPC(8,4)->%d  |  ' ...
            'Huffman->%d  |  HDB3 pulses: %d'], ...
            N0, length(hEnc), length(cEnc), length(bEnc), ...
            length(lEnc), length(hufEnc), sum(hdb3~=0));
        uicontrol('Parent', figC, 'Style', 'text', 'String', infoStr, ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.95 0.9], ...
            'Position', [0.02 0.955 0.96 0.035]);

        subplot(3,2,1);
        stem(0:N0-1, orig, 'filled', 'MarkerSize', 4, 'Color', 'b');
        title(sprintf('① Original Data (%d bits)', N0), 'FontSize', 10);
        ylim([-0.3 1.3]); grid on; ylabel('Bit');

        subplot(3,2,2);
        stem(0:length(hEnc)-1, hEnc, 'filled', 'MarkerSize', 3, 'Color', [0 0.6 0]);
        title(sprintf('② Hamming(7,4) Encoded (%d bits)', length(hEnc)), 'FontSize', 10);
        ylim([-0.3 1.3]); grid on; ylabel('Bit');

        subplot(3,2,3);
        stem(0:length(cEnc)-1, cEnc, 'filled', 'MarkerSize', 3, 'Color', [0.8 0.4 0]);
        title(sprintf('③ CRC-8 Encoded (%d bits, +8 CRC)', length(cEnc)), 'FontSize', 10);
        ylim([-0.3 1.3]); grid on; ylabel('Bit');

        subplot(3,2,4);
        stem(0:length(bEnc)-1, bEnc, 'filled', 'MarkerSize', 3, 'Color', [0.6 0 0.8]);
        title(sprintf('④ BCH(15,7) Encoded (%d bits)', length(bEnc)), 'FontSize', 10);
        ylim([-0.3 1.3]); grid on; ylabel('Bit');

        subplot(3,2,5);
        stem(0:N0-1, hdb3, 'filled', 'MarkerSize', 4, 'Color', [0.8 0 0.4]);
        title('⑤ HDB3 Line Code (3 levels)', 'FontSize', 10);
        ylim([-1.5 1.5]); grid on; ylabel('Level');
        xlabel('Bit Index', 'FontSize', 8);

        subplot(3,2,6);
        stem(0:length(lEnc)-1, lEnc, 'filled', 'MarkerSize', 3, 'Color', [0.2 0.6 1.0]);
        title(sprintf('⑥ LDPC(8,4): %d bits | Huffman: %d bits', ...
            length(lEnc), length(hufEnc)), 'FontSize', 10);
        ylim([-0.3 1.3]); grid on; ylabel('Bit');
        xlabel('Bit Index', 'FontSize', 8);
    end

    %% =====================================================================
    %           ★★★ OFDM 调制 / 解调综合窗口 ★★★
    %  注意：本函数内的 axes 变量一律使用 oax* 前缀，避免与外层主窗口的
    %        ax1/ax2/ax3 变量冲突（嵌套函数共享作用域）。
    %  =====================================================================
    function showOFDMModulator()
        % ---- 读取输入 ----
        dataStr = get(h_data, 'String');
        dataStr = strrep(dataStr, ',', ' ');
        orig = sscanf(dataStr, '%d')';
        if isempty(orig), errordlg('Input data!', 'Warning'); return; end
        snr      = strdoubleOr(get(h_snr, 'String'), 10);
        chanVal  = get(h_chanModel, 'Value');
        modelStr = {'AWGN', 'Rayleigh', 'Rician'};
        chanName = modelStr{chanVal};

        % ---- 创建窗口 ----
        figO = figure('Name', 'OFDM Modulator / Demodulator', ...
            'NumberTitle', 'off', 'Position', [20 20 1600 900], ...
            'Color', [1 1 1], 'MenuBar', 'none', 'ToolBar', 'none');

        % ============ 参数面板 ============
        pnlP = uipanel('Parent', figO, 'Title', 'OFDM Parameters', ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'Units', 'normalized', 'Position', [0.01 0.88 0.98 0.10]);

        uicontrol('Parent', pnlP, 'Style', 'text', 'String', 'Nfft:', ...
            'Units', 'normalized', 'FontSize', 9, 'HorizontalAlignment', 'right', ...
            'Position', [0.02 0.55 0.04 0.32]);
        h_Nfft = uicontrol('Parent', pnlP, 'Style', 'popupmenu', ...
            'String', {'32','64','128','256'}, 'Value', 2, ...
            'Units', 'normalized', 'FontSize', 9, ...
            'Position', [0.07 0.55 0.06 0.35]);

        uicontrol('Parent', pnlP, 'Style', 'text', 'String', 'CP Length:', ...
            'Units', 'normalized', 'FontSize', 9, 'HorizontalAlignment', 'right', ...
            'Position', [0.15 0.55 0.06 0.32]);
        h_Ncp = uicontrol('Parent', pnlP, 'Style', 'edit', 'String', '16', ...
            'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'w', ...
            'Position', [0.22 0.55 0.05 0.35]);

        uicontrol('Parent', pnlP, 'Style', 'text', 'String', 'Subcarrier Mod:', ...
            'Units', 'normalized', 'FontSize', 9, 'HorizontalAlignment', 'right', ...
            'Position', [0.29 0.55 0.10 0.32]);
        h_modType = uicontrol('Parent', pnlP, 'Style', 'popupmenu', ...
            'String', {'QPSK','16-QAM'}, 'Value', 1, ...
            'Units', 'normalized', 'FontSize', 9, ...
            'Position', [0.40 0.55 0.07 0.35]);

        uicontrol('Parent', pnlP, 'Style', 'pushbutton', ...
            'String', 'Apply && Run', ...
            'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.7 0.9 0.7], ...
            'Position', [0.51 0.50 0.10 0.40], ...
            'Callback', @(s,e) runOFDM());

        uicontrol('Parent', pnlP, 'Style', 'text', ...
            'String', '(调整参数后点击 Apply & Run 重新运行)', ...
            'Units', 'normalized', 'FontSize', 8, ...
            'HorizontalAlignment', 'left', 'ForegroundColor', [0.4 0.4 0.4], ...
            'Position', [0.63 0.52 0.35 0.30]);

        % ============ 6 个绘图 axes (用 oax 前缀避免与外层 ax1..ax3 冲突) ============
        oax1 = axes('Parent', figO, 'Units', 'normalized', ...
            'Position', [0.06 0.68 0.42 0.17], 'FontSize', 8);
        oax2 = axes('Parent', figO, 'Units', 'normalized', ...
            'Position', [0.55 0.68 0.42 0.17], 'FontSize', 8);
        oax3 = axes('Parent', figO, 'Units', 'normalized', ...
            'Position', [0.06 0.44 0.42 0.17], 'FontSize', 8);
        oax4 = axes('Parent', figO, 'Units', 'normalized', ...
            'Position', [0.55 0.44 0.42 0.17], 'FontSize', 8);
        oax5 = axes('Parent', figO, 'Units', 'normalized', ...
            'Position', [0.06 0.20 0.42 0.17], 'FontSize', 8);
        oax6 = axes('Parent', figO, 'Units', 'normalized', ...
            'Position', [0.55 0.20 0.42 0.17], 'FontSize', 8);

        oaxInfo = axes('Parent', figO, 'Units', 'normalized', ...
            'Position', [0.03 0.01 0.94 0.16]);
        set(oaxInfo, 'XTick', [], 'YTick', [], 'Box', 'on', ...
            'Color', [0.96 0.98 0.96], 'XColor', 'none', 'YColor', 'none');

        runOFDM();

        % =================================================================
        %  核心执行函数 (嵌套; 使用 oax* 系列 axes)
        % =================================================================
        function runOFDM()
            strsNfft = get(h_Nfft, 'String');
            Nfft = str2double(strsNfft{get(h_Nfft, 'Value')});
            Ncp  = strdoubleOr(get(h_Ncp, 'String'), 16);
            if Ncp < 0 || Ncp >= Nfft, Ncp = floor(Nfft/4); end

            strsMod = get(h_modType, 'String');
            modStr  = strsMod{get(h_modType, 'Value')};
            modSel  = get(h_modType, 'Value');
            if modSel == 1, bitsPerSym = 2; else, bitsPerSym = 4; end

            blockBits = Nfft * bitsPerSym;
            Nb = length(orig);
            padLen = mod(blockBits - mod(Nb, blockBits), blockBits);
            data = [orig, zeros(1, padLen)];
            nOFDMsym = length(data) / blockBits;

            % ---------- 子载波映射 ----------
            tx_symb = zeros(nOFDMsym, Nfft);
            if modSel == 1
                for k = 1:nOFDMsym
                    blk = data((k-1)*blockBits+1 : k*blockBits);
                    b1 = blk(1:2:end); b2 = blk(2:2:end);
                    I = 2*b1 - 1; Q = 2*b2 - 1;
                    tx_symb(k, :) = (I + 1j*Q)/sqrt(2);
                end
                rr = [1 -1 -1 1]/sqrt(2); ri = [1 1 -1 -1]/sqrt(2);
            else
                Itab = [-3 -1 1 3];
                for k = 1:nOFDMsym
                    blk = data((k-1)*blockBits+1 : k*blockBits);
                    for j = 1:Nfft
                        b4 = blk((j-1)*4+1 : j*4);
                        idxI = b4(1)*2 + b4(2);
                        idxQ = b4(3)*2 + b4(4);
                        I = Itab(idxI+1); Q = Itab(idxQ+1);
                        tx_symb(k, j) = (I + 1j*Q)/sqrt(10);
                    end
                end
                ref = [-3 -1 1 3]/sqrt(10);
                [XRef, YRef] = meshgrid(ref, ref);
                rr = XRef(:); ri = YRef(:);
            end

            % ---------- IFFT + 加 CP ----------
            tx_signal = [];
            for k = 1:nOFDMsym
                s = tx_symb(k, :);
                ifft_out = ifft(s, Nfft) * sqrt(Nfft);
                cp = ifft_out(end-Ncp+1:end);
                tx_signal = [tx_signal, cp, ifft_out];
            end

            % ---------- 通过信道 ----------
            sigPow   = mean(abs(tx_signal).^2);
            noisePow = sigPow / 10^(snr/10);
            noise = sqrt(noisePow/2) * (randn(size(tx_signal)) + 1j*randn(size(tx_signal)));

            if chanVal >= 2
                hf = [1, 0.6*exp(1j*pi/3), 0.4*exp(-1j*pi/5)];
                hf = hf / sqrt(sum(abs(hf).^2));
                tx_faded = conv(tx_signal, hf);
                tx_faded = tx_faded(1:length(tx_signal));
                rx_signal = tx_faded + noise;
            else
                rx_signal = tx_signal + noise;
            end

            % ---------- 去 CP + FFT ----------
            rx_symb = zeros(nOFDMsym, Nfft);
            for k = 1:nOFDMsym
                seg = rx_signal((k-1)*(Nfft+Ncp)+1 : k*(Nfft+Ncp));
                fft_out = fft(seg(Ncp+1:end), Nfft) / sqrt(Nfft);
                rx_symb(k, :) = fft_out;
            end

            % ---------- 子载波解调 ----------
            rx_data = zeros(1, blockBits*nOFDMsym);
            if modSel == 1
                for k = 1:nOFDMsym
                    for j = 1:Nfft
                        s = rx_symb(k, j);
                        b1 = double(real(s) > 0);
                        b2 = double(imag(s) > 0);
                        idx = 2*(k-1)*Nfft + 2*j;
                        rx_data(idx-1) = b1;
                        rx_data(idx)   = b2;
                    end
                end
            else
                Itab = [-3 -1 1 3];
                for k = 1:nOFDMsym
                    for j = 1:Nfft
                        s = rx_symb(k, j) * sqrt(10);
                        [~, ii] = min(abs(real(s) - Itab));
                        [~, qi] = min(abs(imag(s) - Itab));
                        bi = ii - 1; bq = qi - 1;
                        b4 = [floor(bi/2), mod(bi,2), floor(bq/2), mod(bq,2)];
                        idx = (k-1)*blockBits + (j-1)*4;
                        rx_data(idx+1 : idx+4) = b4;
                    end
                end
            end

            Lc = min(length(rx_data), Nb);
            errCnt = sum(rx_data(1:Lc) ~= orig(1:Lc));
            berVal = errCnt / max(Lc, 1);

            % ==================== 绘图 ====================
            % ① 输入比特
            axes(oax1); cla(oax1);
            stem(0:Nb-1, orig, 'filled', 'MarkerSize', 3, 'Color', 'b');
            title(sprintf('① Input Data: %d bits', Nb), 'FontSize', 10);
            ylim([-0.3 1.3]); grid(oax1, 'on');
            xlabel('Bit Index'); ylabel('Bit');

            % ② 发射子载波星座图
            axes(oax2); cla(oax2); hold(oax2, 'on');
            plot(oax2, [-1.6 1.6], [0 0], 'k:', 'HandleVisibility','off');
            plot(oax2, [0 0], [-1.6 1.6], 'k:', 'HandleVisibility','off');
            txS = tx_symb(:);
            plot(oax2, real(txS), imag(txS), 'bo', 'MarkerSize', 6);
            plot(oax2, rr, ri, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
            hold(oax2, 'off');
            title(sprintf('② Tx Subcarrier Symbols (%s)', modStr), 'FontSize', 10);
            axis(oax2, 'equal'); grid(oax2, 'on');
            xlim(oax2, [-1.6 1.6]); ylim(oax2, [-1.6 1.6]);
            xlabel('I'); ylabel('Q');

            % ③ OFDM 时域信号 (含 CP)
            axes(oax3); cla(oax3);
            nShow = min(2*(Nfft+Ncp), length(tx_signal));
            plot(oax3, real(tx_signal(1:nShow)), 'b', 'LineWidth', 1.0); hold(oax3, 'on');
            plot(oax3, imag(tx_signal(1:nShow)), 'r', 'LineWidth', 1.0);
            for kk = 0:min(2, nOFDMsym)-1
                xv = kk*(Nfft+Ncp)+1;
                plot(oax3, [xv xv], [-3 3], 'k--', 'LineWidth', 0.4);
            end
            hold(oax3, 'off');
            title(sprintf('③ OFDM Time Signal (Nfft=%d, CP=%d)', Nfft, Ncp), ...
                'FontSize', 10);
            grid(oax3, 'on'); xlabel('Sample'); ylabel('Amplitude');
            legend(oax3, 'Real','Imag','Location','best','FontSize',7);

            % ④ 频谱
            axes(oax4); cla(oax4);
            Ns = 2^nextpow2(length(tx_signal));
            Px = fftshift(abs(fft(tx_signal, Ns)).^2) / length(tx_signal);
            fx = (-Ns/2 : Ns/2-1) / Ns;
            plot(oax4, fx, 10*log10(Px + eps), 'b', 'LineWidth', 1.0);
            title('④ OFDM Signal Spectrum', 'FontSize', 10);
            xlabel('Norm. Freq'); ylabel('PSD (dB)');
            grid(oax4, 'on'); xlim(oax4, [-0.5 0.5]);

            % ⑤ 接收子载波星座图
            axes(oax5); cla(oax5); hold(oax5, 'on');
            plot(oax5, [-1.6 1.6], [0 0], 'k:', 'HandleVisibility','off');
            plot(oax5, [0 0], [-1.6 1.6], 'k:', 'HandleVisibility','off');
            rxS = rx_symb(:);
            plot(oax5, real(rxS), imag(rxS), 'r.', 'MarkerSize', 14);
            plot(oax5, rr, ri, 'kx', 'MarkerSize', 10, 'LineWidth', 2);
            hold(oax5, 'off');
            title(sprintf('⑤ Rx Subcarrier Symbols (%s channel)', chanName), ...
                'FontSize', 10);
            axis(oax5, 'equal'); grid(oax5, 'on');
            xlim(oax5, [-1.6 1.6]); ylim(oax5, [-1.6 1.6]);
            xlabel('I'); ylabel('Q');
            legend(oax5, {'Rx', 'Ref'}, 'Location','best','FontSize',7);

            % ⑥ 每子载波平均 |H| 估计
            axes(oax6); cla(oax6);
            Hest = mean(rx_symb .* conj(tx_symb), 1) ./ ...
                   (mean(abs(tx_symb).^2, 1) + eps);
            stem(oax6, 0:Nfft-1, abs(Hest), 'filled', ...
                'MarkerSize', 3, 'Color', [0.2 0.5 0.9]);
            hold(oax6, 'on');
            plot(oax6, [0 Nfft-1], [1 1], 'k--', 'LineWidth', 1.0);
            hold(oax6, 'off');
            title('⑥ Per-subcarrier |H| estimate', 'FontSize', 10);
            xlabel('Subcarrier Index'); ylabel('|H|');
            grid(oax6, 'on');

            % ============ 底部信息区 ============
            axes(oaxInfo); cla(oaxInfo); axis(oaxInfo, [0 1 0 1]);
            infoLines = {
                sprintf(['Nfft = %d  |  CP = %d  |  Subcarrier Mod = %s  |  ' ...
                    'Channel = %s  |  SNR = %.2f dB'], ...
                    Nfft, Ncp, modStr, chanName, snr), ...
                sprintf(['OFDM symbols = %d  |  Total Tx samples = %d  |  ' ...
                    'Bits/subcarrier = %d  |  Total Tx bits = %d'], ...
                    nOFDMsym, length(tx_signal), bitsPerSym, blockBits*nOFDMsym), ...
                sprintf(['Errors = %d / %d bits  |  BER = %.3e  |  ' ...
                    'CP overhead = %.1f%%  |  Spectral Eff = %.2f bit/sym'], ...
                    errCnt, Lc, berVal, Ncp/(Nfft+Ncp)*100, ...
                    bitsPerSym * Nfft / (Nfft + Ncp)), ...
                '说明：IFFT 后加 CP 抵抗多径；接收端去 CP 后 FFT，再按子载波解调。'
            };
            text(0.01, 0.95, infoLines, 'Parent', oaxInfo, ...
                'VerticalAlignment', 'top', 'FontSize', 9, ...
                'FontName', 'FixedWidth');
            set(oaxInfo, 'XTick', [], 'YTick', []);

            drawnow;
        end
    end

    function v = strdoubleOr(s, def)
        v = str2double(s); if isnan(v), v = def; end
    end

    %% ---------------- 画箭头辅助函数 ----------------
    function drawArrow(ax, x1, y1, x2, y2)
        arrowLenRatio = 0.12;
        dx = x2 - x1; dy = y2 - y1;
        L  = sqrt(dx^2 + dy^2);
        if L < 1e-6, return; end
        ux = dx / L; uy = dy / L;
        xe = x2 - ux * L * arrowLenRatio;
        ye = y2 - uy * L * arrowLenRatio;
        plot(ax, [x1 xe], [y1 ye], 'k-', 'LineWidth', 1.1);
        quiver(ax, xe, ye, ux * L * arrowLenRatio, uy * L * arrowLenRatio, ...
            0, 'k', 'MaxHeadSize', 3.0, 'LineWidth', 1.1);
    end

    %% ---------------- Conv Viewer ----------------
    function showConvCodeViewer()
        dataStr = get(h_data, 'String');
        dataStr = strrep(dataStr, ',', ' ');
        orig = sscanf(dataStr, '%d')';
        if isempty(orig), errordlg('Input data!', 'Warning'); return; end
        N0 = length(orig);
        snr = str2double(get(h_snr, 'String')); if isnan(snr), snr = 10; end
        pErr = 0.5 * erfc(sqrt(10^(snr/10)));
        enc = conv_encode_217(orig);
        L = length(enc);
        errs = rand(1, L) < pErr;
        rx = mod(enc + errs, 2);
        dec = viterbi_decode_217(rx, N0);
        eB = sum(errs); eA = sum(orig ~= dec);

        figV = figure('Name', 'Conv. Code Viewer', 'NumberTitle', 'off', ...
            'Position', [80 40 1200 800], 'Color', [1 1 1]);
        infoStr = sprintf(['Orig: %d | Enc: %d | BSC p=%.2e | ' ...
            'Ch err: %d | After Viterbi: %d'], N0, L, pErr, eB, eA);
        uicontrol('Parent', figV, 'Style', 'text', 'String', infoStr, ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', 10, 'BackgroundColor', [0.95 0.95 0.85], ...
            'Position', [0.02 0.955 0.96 0.035]);
        subplot(5,1,1);
        stem(0:N0-1, orig, 'filled', 'MarkerSize', 4, 'Color', 'b');
        title('① Original'); grid on; ylim([-0.3 1.3]);
        subplot(5,1,2);
        stem(0:L-1, enc, 'filled', 'MarkerSize', 3, 'Color', [0 0.6 0]);
        title('② Encoded'); grid on; ylim([-0.3 1.3]);
        subplot(5,1,3);
        stem(0:L-1, rx, 'filled', 'MarkerSize', 3, 'Color', [0.8 0.4 0]);
        hold on; eIdx = find(errs);
        if ~isempty(eIdx), plot(eIdx-1, rx(eIdx), 'ro', 'MarkerSize', 8); end
        hold off; title(sprintf('③ After BSC (%d errors)', eB));
        grid on; ylim([-0.3 1.3]);
        subplot(5,1,4);
        stem(0:N0-1, dec, 'filled', 'MarkerSize', 4, 'Color', [0.6 0 0.8]);
        hold on; e2 = find(orig ~= dec);
        if ~isempty(e2), plot(e2-1, dec(e2), 'rs', 'MarkerSize', 10); end
        hold off; title(sprintf('④ After Viterbi (%d errors)', eA));
        grid on; ylim([-0.3 1.3]);
        subplot(5,1,5);
        stem(0:N0-1, orig, 'filled', 'MarkerSize', 4, 'Color', [0.5 0.5 0.5]); hold on;
        stem(0:N0-1, dec+0.05, 'filled', 'MarkerSize', 4, 'Color', [0 0.5 0.9]);
        hold off; grid on; ylim([-0.3 1.3]); title('⑤ Compare');
    end

    %% ---------------- 主绘图 ----------------
    function updatePlots()
        dataUp = kron(currentData, ones(1, 100));
        snr = str2double(get(h_snr, 'String')); if isnan(snr), snr = 10; end
        useConv = get(h_useConv, 'Value') == 1;
        modelType = get(h_chanModel, 'Value');
        modelStr = {'AWGN', 'Rayleigh', 'Rician'};
        chanName = modelStr{modelType};

        axes(ax1); cla(ax1); stairs(ax1, currentT, dataUp, 'b', 'LineWidth', 1.5);
        title(ax1, 'Digital Data', 'FontSize', 9); grid(ax1, 'on');
        ylim(ax1, [-2 2]); xlim(ax1, [0 length(currentT)]); set(ax1, 'XTickLabel', []);

        axes(ax2); cla(ax2);
        if isstruct(currentCarrier)
            plot(ax2, currentT, currentCarrier.c1, 'b', 'LineWidth', 0.8);
        else
            plot(ax2, currentT, currentCarrier, 'b', 'LineWidth', 0.8);
        end
        title(ax2, [currentMod ' Carrier'], 'FontSize', 9); grid(ax2, 'on');
        ylim(ax2, [-2 2]); xlim(ax2, [0 length(currentT)]); set(ax2, 'XTickLabel', []);

        axes(ax3); cla(ax3); plot(ax3, currentT, currentModSignal, 'b', 'LineWidth', 0.8);
        title(ax3, sprintf('%s modulation  (via %s channel)', currentMod, chanName), ...
            'FontSize', 9); grid(ax3, 'on');
        ylim(ax3, [-2 2]); xlim(ax3, [0 length(currentT)]); xlabel(ax3, 'Samples');

        axes(axSpec); cla(axSpec);
        L = length(currentModSignal); Nfft = 2^nextpow2(L);
        Sf = fft(currentModSignal, Nfft); Pxx = abs(Sf).^2 / L;
        Pxx = Pxx(1:floor(Nfft/2)+1); Pxx(2:end-1) = 2*Pxx(2:end-1);
        Fn = (0:floor(Nfft/2)) / Nfft;
        plot(axSpec, Fn, 10*log10(Pxx + eps), 'b', 'LineWidth', 0.9);
        title(axSpec, [currentMod ' Spectrum'], 'FontSize', 10);
        xlabel(axSpec, 'Norm. Freq'); ylabel(axSpec, 'PSD (dB)');
        grid(axSpec, 'on'); xlim(axSpec, [0 0.5]);

        axes(axConst); cla(axConst); hold(axConst, 'on');
        plot(axConst, [-1.6 1.6], [0 0], 'k:', 'HandleVisibility','off');
        plot(axConst, [0 0], [-1.6 1.6], 'k:', 'HandleVisibility','off');
        switch currentMod
            case {'BPSK','DPSK'}, refI=[-1 1]; refQ=[0 0];
            case 'QPSK', refI=[1 0 -1 0]; refQ=[0 1 0 -1];
            case 'QAM'
                [XI,YI] = meshgrid([-1 -1/3 1/3 1], [-1/3 1/3]);
                refI = XI(:); refQ = YI(:);
            case 'ASK', refI=[0.5 1]; refQ=[0 0];
            otherwise, refI=[]; refQ=[];
        end
        hRef = [];
        if ~isempty(refI)
            hRef = plot(axConst, refI, refQ, 'x', 'Color', [0.5 0.5 0.5], ...
                'MarkerSize', 12, 'LineWidth', 2);
        end
        if strcmp(currentMod,'FSK')
            tc = linspace(0,2*pi,200);
            plot(axConst, cos(tc), sin(tc), 'k--', 'HandleVisibility','off');
        end
        hI = plot(axConst, real(currentBB), imag(currentBB), 'bo', 'MarkerSize', 9);
        hN = plot(axConst, real(currentBB_Rx), imag(currentBB_Rx), '.', ...
            'Color', [1 0.2 0.2], 'MarkerSize', 20);
        hold(axConst, 'off');
        title(axConst, sprintf('%s Constellation  [%s, SNR=%g]', ...
            currentMod, chanName, snr));
        xlabel(axConst, 'I'); ylabel(axConst, 'Q'); grid(axConst, 'on');
        axis(axConst, 'equal'); xlim(axConst, [-1.6 1.6]); ylim(axConst, [-1.6 1.6]);
        if ~isempty(hRef)
            legend(axConst, [hRef hI hN], {'Ref','Ideal','Rx(Faded+Noisy)'}, ...
                'Location','southoutside','Orientation','horizontal','FontSize',7);
        end

        % ============ BER 曲线 ============
        axes(axBER); cla(axBER);
        EbN0 = 0:1:16; EbN0lin = 10.^(EbN0/10);
        switch modelType
            case 1  % AWGN
                switch currentMod
                    case {'BPSK','QPSK'}, b0 = 0.5*erfc(sqrt(EbN0lin));
                    case 'QAM',            b0 = (2/3)*erfc(sqrt(3*EbN0lin/14));
                    case 'DPSK',           b0 = 0.5*exp(-EbN0lin);
                    case 'ASK',            b0 = 0.5*erfc(sqrt(EbN0lin/4));
                    case 'FSK',            b0 = 0.5*erfc(sqrt(EbN0lin/2));
                    otherwise,             b0 = 0.5*erfc(sqrt(EbN0lin));
                end
                curveTag = 'AWGN theory';
            case 2  % Rayleigh
                switch currentMod
                    case {'BPSK','QPSK'}, b0 = 0.5*(1 - sqrt(EbN0lin./(1+EbN0lin)));
                    case 'DPSK',           b0 = 1./(2*(1+EbN0lin));
                    case 'FSK',            b0 = 1./(2+EbN0lin);
                    otherwise,             b0 = 0.5*(1 - sqrt(EbN0lin./(1+EbN0lin)));
                end
                curveTag = 'Rayleigh theory';
            case 3  % Rician
                Klin = 10^(strdoubleOr(get(h_kFactor,'String'), 10)/10);
                raylCurve = 0.5*(1 - sqrt(EbN0lin./(1+EbN0lin)));
                awgnCurve = 0.5*erfc(sqrt(EbN0lin));
                w_los = Klin / (Klin + 1);
                b0 = w_los * awgnCurve + (1-w_los) * raylCurve;
                curveTag = sprintf('Rician theory (K=%.1f dB)', 10*log10(Klin));
            otherwise
                b0 = 0.5*erfc(sqrt(EbN0lin));
                curveTag = 'AWGN theory';
        end
        b0(b0<1e-12) = 1e-12;

        hold(axBER, 'on');
        h1 = semilogy(axBER, EbN0, b0, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
        sIdx = find(EbN0 >= snr, 1); hC = [];
        if ~isempty(sIdx)
            hC = semilogy(axBER, EbN0(sIdx), b0(sIdx), 'rp', ...
                'MarkerSize', 14, 'MarkerFaceColor', 'r');
        end
        h2 = [];
        if useConv
            bc = 0.5*erfc(sqrt(2*EbN0lin)); bc(bc<1e-12)=1e-12;
            h2 = semilogy(axBER, EbN0, bc, 'g--s', 'LineWidth', 1.5);
        end
        hold(axBER, 'off');
        title(axBER, sprintf('%s BER over %s', currentMod, chanName));
        xlabel(axBER, 'Eb/N0 (dB)'); ylabel(axBER, 'BER');
        grid(axBER, 'on'); ylim(axBER, [1e-6 1]); xlim(axBER, [0 16]);

        if useConv && ~isempty(hC)
            legend(axBER, [h1 h2 hC], {curveTag, 'Conv', 'Current'}, ...
                'Location','southwest','FontSize',7);
        elseif ~isempty(hC)
            legend(axBER, [h1 hC], {curveTag, 'Current'}, ...
                'Location','southwest','FontSize',7);
        end
        drawnow;
    end

    %% ---------------- Show Figure ----------------
    function showCurrentFigure()
        if isempty(currentModSignal), return; end
        figure('Name', ['Figure - ' currentMod], 'NumberTitle', 'off', ...
            'Position', [50 50 1200 750], 'Color', [1 1 1]);

        subplot(3,2,1); plot(currentT, currentModSignal, 'b');
        title([currentMod ' modulation']); grid on;

        subplot(3,2,2); plot(real(currentBB), imag(currentBB), 'bo');
        hold on;
        plot(real(currentBB_Rx), imag(currentBB_Rx), 'r.'); hold off;
        axis equal; grid on; title('Constellation');

        subplot(3,2,3);
        plot(1:length(currentModSignal), currentModSignal); grid on;
        title('Time Signal');

        % ★ 修复：x 轴用半长度向量，y 轴取 fft 的前一半
        subplot(3,2,4);
        L  = length(currentModSignal);
        Xf = fft(currentModSignal);
        Lh = floor(L/2);
        Xh = Xf(1:Lh);
        plot((0:Lh-1)/L, 20*log10(abs(Xh)/L + eps));
        title('Spectrum (dB)'); grid on;

        subplot(3,2,[5 6]);
        if ~isempty(currentRxBits)
            Lb = min(length(currentRxBits), length(currentData));
            stairs(0:Lb-1, currentData(1:Lb), 'b', 'LineWidth', 1.2); hold on;
            stairs(0:Lb-1, currentRxBits(1:Lb) + 0.06, 'r', 'LineWidth', 1.0);
            hold off; grid on; ylim([-0.3 1.4]);
            errIdx = find(currentRxBits(1:Lb) ~= currentData(1:Lb));
            title(sprintf('Demodulated Bits vs Tx  (Errors=%d, BER=%.3e)', ...
                length(errIdx), length(errIdx)/Lb));
            legend('Tx (encoded)','Rx (demodulated)','Location','best');
        end
    end

    %% ---------------- 初始化 ----------------
    runModulation('BPSK');
end