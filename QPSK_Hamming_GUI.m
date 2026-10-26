function QPSK_Hamming_GUI()
% QPSK调制解调 + 汉明编解码 + 星座图 仿真 GUI（R2015a 完美兼容版）
% 使用方法：命令行输入 QPSK_Hamming_GUI

    fName = '黑体'; 

    % ============ 主窗口 ============
    mainFig = figure('Name','QPSK 综合仿真系统','NumberTitle','off', ...
        'Units','normalized','Position',[0.03 0.05 0.94 0.88], ...
        'Color',[0.94 0.94 0.94],'MenuBar','none','ToolBar','figure', ...
        'Renderer', 'painters', ...
        'DefaultUicontrolFontName', fName, 'DefaultAxesFontName', fName, ...
        'DefaultTextFontName', fName);

    pnlBg = [0.94 0.94 0.94];

    % ============ 左侧参数面板 ============
    pnl = uipanel(mainFig,'Title','参数设置','Units','normalized', ...
        'Position',[0.01 0.01 0.17 0.98],'FontSize',10,'BackgroundColor',pnlBg, ...
        'FontName', fName);

    lbl = {'码元数 M','每码元采样 L','码元宽度 Ts (s)','载波频率 fc (Hz)','信噪比 SNR (dB)'};
    dft = {'20','100','0.001','2000','20'};
    edt = cell(1,5);
    ypos = 0.94;
    for i = 1:5
        uicontrol(pnl,'Style','text','Units','normalized', ...
            'Position',[0.06 ypos 0.88 0.04],'String',lbl{i}, ...
            'HorizontalAlignment','left','FontSize',9,'BackgroundColor',pnlBg, ...
            'FontName', fName);
        edt{i} = uicontrol(pnl,'Style','edit','Units','normalized', ...
            'Position',[0.06 ypos-0.045 0.88 0.045],'String',dft{i}, ...
            'FontSize',10,'BackgroundColor',[1 1 1],'FontName', fName);
        ypos = ypos - 0.09;
    end

    chkHamming = uicontrol(pnl,'Style','checkbox','Units','normalized', ...
        'Position',[0.06 0.41 0.88 0.05],'String','启用(7,4)汉明码', ...
        'Value',1,'FontSize',9,'BackgroundColor',pnlBg,'FontName', fName);

    uicontrol(pnl,'Style','pushbutton','Units','normalized', ...
        'Position',[0.06 0.33 0.88 0.07],'String','开始仿真', ...
        'FontSize',12,'FontWeight','bold','Callback',@onRun, ...
        'BackgroundColor',[0.3 0.7 0.3],'ForegroundColor',[1 1 1],'FontName', fName);
    uicontrol(pnl,'Style','pushbutton','Units','normalized', ...
        'Position',[0.06 0.25 0.88 0.06],'String','重置参数', ...
        'FontSize',10,'Callback',@onReset,'FontName', fName);

    % ---- 修复仿真结果显示区 ----
    uicontrol(pnl,'Style','text','Units','normalized', ...
        'Position',[0.06 0.19 0.88 0.04],'String','仿真结果：', ...
        'HorizontalAlignment','left','FontSize',10,'FontWeight','bold', ...
        'BackgroundColor',pnlBg,'FontName',fName);
    
    resultText = uicontrol(pnl,'Style','edit','Max',5,'Min',0,'Enable','inactive', ...
        'Units','normalized','Position',[0.04 0.02 0.92 0.16], ...
        'String','等待仿真...', ...
        'FontSize',9,'HorizontalAlignment','left','BackgroundColor',[1 1 1], ...
        'FontName', fName);

    % ============ 右侧 Tabgroup ============
    tg = uitabgroup(mainFig,'Units','normalized','Position',[0.19 0.01 0.80 0.98]);

    % --- Tab 1 ---
    tab1 = uitab(tg,'Title','基带/I/Q波形');
    ax1a = axes('Parent',tab1,'Units','normalized','Position',[0.10 0.73 0.80 0.22]);
    ax1b = axes('Parent',tab1,'Units','normalized','Position',[0.10 0.41 0.80 0.22]);
    ax1c = axes('Parent',tab1,'Units','normalized','Position',[0.10 0.09 0.80 0.22]);

    % --- Tab 2 ---
    tab2 = uitab(tg,'Title','QPSK调制与信道');
    ax2a = axes('Parent',tab2,'Units','normalized','Position',[0.10 0.59 0.80 0.36]);
    ax2b = axes('Parent',tab2,'Units','normalized','Position',[0.10 0.08 0.80 0.36]);

    % --- Tab 3 ---
    tab3 = uitab(tg,'Title','相干解调');
    ax3a = axes('Parent',tab3,'Units','normalized','Position',[0.10 0.59 0.80 0.36]);
    ax3b = axes('Parent',tab3,'Units','normalized','Position',[0.10 0.08 0.80 0.36]);

    % --- Tab 4 ---
    tab4 = uitab(tg,'Title','低通滤波');
    ax4a = axes('Parent',tab4,'Units','normalized','Position',[0.10 0.73 0.80 0.22]);
    ax4b = axes('Parent',tab4,'Units','normalized','Position',[0.10 0.41 0.80 0.22]);
    ax4c = axes('Parent',tab4,'Units','normalized','Position',[0.10 0.09 0.80 0.22]);

    % --- Tab 5 ---
    tab5 = uitab(tg,'Title','抽样判决与合并');
    ax5a = axes('Parent',tab5,'Units','normalized','Position',[0.10 0.73 0.80 0.22]);
    ax5b = axes('Parent',tab5,'Units','normalized','Position',[0.10 0.41 0.80 0.22]);
    ax5c = axes('Parent',tab5,'Units','normalized','Position',[0.10 0.09 0.80 0.22]);

    % --- Tab 6 ---
    tab6 = uitab(tg,'Title','频谱分析');
    ax6a = axes('Parent',tab6,'Units','normalized','Position',[0.10 0.73 0.80 0.22]);
    ax6b = axes('Parent',tab6,'Units','normalized','Position',[0.10 0.41 0.80 0.22]);
    ax6c = axes('Parent',tab6,'Units','normalized','Position',[0.10 0.09 0.80 0.22]);

    % --- Tab 7 ---
    tab7 = uitab(tg,'Title','汉明编解码');
    ax7a = axes('Parent',tab7,'Units','normalized','Position',[0.10 0.73 0.80 0.22]);
    ax7b = axes('Parent',tab7,'Units','normalized','Position',[0.10 0.41 0.80 0.22]);
    ax7c = axes('Parent',tab7,'Units','normalized','Position',[0.10 0.09 0.80 0.22]);

    % --- Tab 8 (星座图) ---
    tab8 = uitab(tg,'Title','星座图');
    ax8a = axes('Parent',tab8,'Units','normalized','Position',[0.15 0.12 0.65 0.78]); 

    allAxes = [ax1a ax1b ax1c ax2a ax2b ax3a ax3b ...
               ax4a ax4b ax4c ax5a ax5b ax5c ax6a ax6b ax6c ax7a ax7b ax7c ax8a];
    set(allAxes,'Box','on','FontSize',8,'FontName', fName);

    % ============ 回调 ============
    function onReset(~,~)
        for i = 1:5
            set(edt{i},'String',dft{i});
        end
        set(chkHamming,'Value',1);
        for k = 1:numel(allAxes)
            cla(allAxes(k));
        end
        set(resultText,'String','等待仿真...');
    end

    function onRun(~,~)
        % ---- 读取参数 ----
        M   = str2double(get(edt{1},'String'));
        L   = str2double(get(edt{2},'String'));
        Ts  = str2double(get(edt{3},'String'));
        fc  = str2double(get(edt{4},'String'));
        snr = str2double(get(edt{5},'String'));
        useHamming = get(chkHamming,'Value') == 1;

        if any(isnan([M L Ts fc snr])) || M < 2 || L < 4 || Ts <= 0 || fc <= 0
            errordlg('参数不合法，请检查输入！','参数错误');
            return;
        end
        M = round(M); L = round(L);

        % ---- 基本时间参数 ----
        Rb = 1/Ts;
        dt = Ts/L;
        Fs = 1/dt;

        % ---- 产生原始比特 ----
        bits = randi([0,1],1,M);

        % ---- (7,4) 汉明编码 ----
        if useHamming
            k = 4; n = 7;
            pad = mod(k - mod(M,k), k);
            if pad == k, pad = 0; end
            bits_pad = [bits, zeros(1,pad)];
            M_pad = length(bits_pad);
            nBlocks = M_pad / k;

            G = [1 0 0 0 1 1 0;
                 0 1 0 0 1 0 1;
                 0 0 1 0 0 1 1;
                 0 0 0 1 1 1 1];
            H = [1 1 0 1 1 0 0;
                 1 0 1 1 0 1 0;
                 0 1 1 1 0 0 1];

            txBits = zeros(1, nBlocks*n);
            for i = 1:nBlocks
                mvec = bits_pad((i-1)*k+1 : i*k);
                txBits((i-1)*n+1 : i*n) = mod(mvec * G, 2);
            end
        else
            txBits = bits;
            k = 1; n = 1; nBlocks = M;
        end

        % ---- QPSK 需要偶数比特 ----
        if mod(length(txBits), 2) ~= 0
            txBits = [txBits, 0];
        end
        Mmod = length(txBits);
        txWave = 2*txBits - 1;

        % ---- 时间轴 ----
        TotalTmod = Mmod*Ts;
        tMod = 0:dt:TotalTmod-dt;
        TotalT2 = (Mmod/2)*Ts;
        t2 = 0:dt:TotalT2-dt;

        % ---- 基带波形 ----
        fz = ones(1,L);
        x1 = txWave(fz,:);
        jidai = reshape(x1,1,L*Mmod);

        % ---- I/Q 分路 ----
        I = []; Q = [];
        for i = 1:Mmod
            if mod(i,2) ~= 0
                I = [I, txWave(i)];
            else
                Q = [Q, txWave(i)];
            end
        end
        x2 = I(fz,:); I_lu = reshape(x2,1,L*(Mmod/2));
        x3 = Q(fz,:); Q_lu = reshape(x3,1,L*(Mmod/2));

        % ---- QPSK 调制 ----
        zb1 = cos(2*pi*fc*t2);
        zb2 = sin(2*pi*fc*t2);
        qpsk = I_lu.*zb1 + Q_lu.*zb2;

        % ---- AWGN ----
        tz = awgn(qpsk, snr);

        % ---- 相干解调 ----
        tz1 = tz.*zb1;
        tz2 = tz.*zb2;

        % ---- 低通滤波 ----
        fp = 2*Rb;
        b = fir1(30, fp/Fs, rectwin(31));
        [h,w] = freqz(b,1,512);
        lvbo1 = fftfilt(b,tz1);
        lvbo2 = fftfilt(b,tz2);

        % ---- 抽样判决 ----
        pdst1 = 1*(lvbo1 > 0);
        pdst2 = 1*(lvbo2 > 0);

        I_zong = []; Q_zong = [];
        for jj = L/2:L:(L*Mmod/2)
            if pdst1(jj) > 0, I_zong=[I_zong,1]; else I_zong=[I_zong,0]; end
        end
        for kk = L/2:L:(L*Mmod/2)
            if pdst2(kk) > 0, Q_zong=[Q_zong,1]; else Q_zong=[Q_zong,0]; end
        end

        rxBits = zeros(1, Mmod);
        for ni = 1:Mmod
            if mod(ni,2) ~= 0
                rxBits(ni) = I_zong((ni+1)/2);
            else
                rxBits(ni) = Q_zong(ni/2);
            end
        end

        % ---- (7,4) 汉明解码 ----
        if useHamming
            decBits = zeros(1, nBlocks*k);
            for i = 1:nBlocks
                r = rxBits((i-1)*n+1 : i*n);
                s = mod(r * H', 2);
                if any(s)
                    for col = 1:n
                        if isequal(H(:,col)', s)
                            r(col) = 1 - r(col);   % 纠正单比特错误
                            break;
                        end
                    end
                end
                decBits((i-1)*k+1 : i*k) = r(1:k);
            end
            decBits = decBits(1:M);
        else
            decBits = rxBits(1:M);
        end

        % ---- 误码统计 ----
        txErr = sum(rxBits ~= txBits);
        txBer = txErr / Mmod;
        decErr = sum(decBits ~= bits);
        decBer = decErr / M;

        % ---- 合并波形 ----
        codeBip = 2*rxBits - 1;
        x4 = codeBip(fz,:);
        dout = reshape(x4,1,L*Mmod);

        % ---- 频谱 ----
        Tmod = tMod(end); dfm = 1/Tmod; Nm = length(jidai);
        fm = (-Nm/2:Nm/2-1)*dfm;
        mf = fftshift(abs(fft(jidai)));
        T2 = t2(end); df2 = 1/T2; N2 = length(qpsk);
        f2 = (-N2/2:N2/2-1)*df2;
        sf = fftshift(abs(fft(qpsk)));
        dmf1 = fftshift(abs(fft(lvbo1)));
        dmf2 = fftshift(abs(fft(lvbo2)));

        % ================ 绘图 ================
        % Tab1
        axes(ax1a); cla; plot(tMod, jidai,'LineWidth',1.5); grid on;
        title(sprintf('传 输 基 带 波 形 (%d 位)', Mmod), 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalTmod -1.1 1.1]);

        axes(ax1b); cla; plot(t2, I_lu,'LineWidth',1.5); grid on;
        title('I 路 信 号 波 形', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -1.1 1.1]);

        axes(ax1c); cla; plot(t2, Q_lu,'LineWidth',1.5); grid on;
        title('Q 路 信 号 波 形', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -1.1 1.1]);

        % Tab2
        axes(ax2a); cla; plot(t2, qpsk,'LineWidth',1.0); grid on;
        title('Q P S K 信 号 波 形', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -2.1 2.1]);

        axes(ax2b); cla; plot(t2, tz,'LineWidth',1.0); grid on;
        title(sprintf('加 A W G N 后 波 形 (SNR=%g dB)', snr), 'FontName', fName);
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -2.5 2.5]);

        % Tab3
        axes(ax3a); cla; plot(t2, tz1,'LineWidth',1.0); grid on;
        title('I 路 乘 相 干 载 波', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -2.5 2.5]);

        axes(ax3b); cla; plot(t2, tz2,'LineWidth',1.0); grid on;
        title('Q 路 乘 相 干 载 波', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -2.5 2.5]);

        % Tab4
        axes(ax4a); cla; plot(w/pi*Fs/2, 20*log10(abs(h)+eps),'LineWidth',1.5); grid on;
        title('低 通 滤 波 器 幅 频 响 应', 'FontName', fName); 
        xlabel('频 率 / Hz', 'FontName', fName); ylabel('幅 度 / dB', 'FontName', fName);

        axes(ax4b); cla; plot(t2, lvbo1,'LineWidth',1.0); grid on;
        title('I 路 滤 波 后', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -2.1 2.1]);

        axes(ax4c); cla; plot(t2, lvbo2,'LineWidth',1.0); grid on;
        title('Q 路 滤 波 后', 'FontName', fName);
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -2.1 2.1]);

        % Tab5
        axes(ax5a); cla; plot(t2, pdst1,'LineWidth',1.0); grid on;
        title('I 路 判 决 结 果', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -0.1 1.1]);

        axes(ax5b); cla; plot(t2, pdst2,'LineWidth',1.0); grid on;
        title('Q 路 判 决 结 果', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalT2 -0.1 1.1]);

        axes(ax5c); cla; plot(tMod, dout,'LineWidth',1.5); grid on;
        title('合 并 恢 复 波 形', 'FontName', fName); 
        xlabel('时 间 / s', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([0 TotalTmod -1.1 1.1]);

        % Tab6
        axes(ax6a); cla; plot(fm, mf,'LineWidth',1.0); grid on;
        title('基 带 信 号 频 谱', 'FontName', fName); 
        xlabel('频 率 / Hz', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([-20000 20000 0 inf]);

        axes(ax6b); cla; plot(f2, sf,'LineWidth',1.0); grid on;
        title('Q P S K 信 号 频 谱', 'FontName', fName); 
        xlabel('频 率 / Hz', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        axis([-20000 20000 0 inf]);

        axes(ax6c); cla;
        plot(f2, dmf1,'b','LineWidth',1.0); hold on;
        plot(f2, dmf2,'r','LineWidth',1.0); hold off; grid on;
        title('滤 波 后 I / Q 频 谱', 'FontName', fName); 
        xlabel('频 率 / Hz', 'FontName', fName); ylabel('幅 度', 'FontName', fName);
        legend('I 路','Q 路','Location','best');

        % Tab7
        axes(ax7a); cla;
        stairs(1:M, bits, 'b', 'LineWidth', 1.5); grid on;
        title(sprintf('原 始 比 特 流 (%d 位)', M), 'FontName', fName);
        xlabel('比 特 序 号', 'FontName', fName); ylabel('值', 'FontName', fName);
        axis([0.5 M+0.5 -0.2 1.2]);

        axes(ax7b); cla;
        stairs(1:Mmod, txBits, 'b', 'LineWidth', 1.5); hold on;
        errIdx = find(rxBits ~= txBits);
        if ~isempty(errIdx)
            plot(errIdx, rxBits(errIdx)+0.05, 'rx', 'MarkerSize', 8, 'LineWidth', 1.5);
        end
        hold off; grid on;
        if useHamming
            title(sprintf('编 码 传 输 码 字 (%d 位)  红 x = 接 收 错 误', Mmod), 'FontName', fName);
        else
            title(sprintf('传 输 比 特 (%d 位, 未 编 码)  红 x = 接 收 错 误', Mmod), 'FontName', fName);
        end
        xlabel('比 特 序 号', 'FontName', fName); ylabel('值', 'FontName', fName);
        axis([0.5 Mmod+0.5 -0.2 1.2]);

        axes(ax7c); cla;
        stairs(1:M, decBits, 'b', 'LineWidth', 1.5); hold on;
        errIdx2 = find(decBits ~= bits);
        if ~isempty(errIdx2)
            plot(errIdx2, decBits(errIdx2)+0.05, 'rx', 'MarkerSize', 8, 'LineWidth', 1.5);
        end
        hold off; grid on;
        title(sprintf('解 码 后 比 特 流 (%d 位)  红 x = 残 留 错 误', M), 'FontName', fName);
        xlabel('比 特 序 号', 'FontName', fName); ylabel('值', 'FontName', fName);
        axis([0.5 M+0.5 -0.2 1.2]);

        % Tab8: 星座图 (兼容 R2015a 的手动十字坐标)
        axes(ax8a); cla;
        I_tx = txWave(1:2:end);
        Q_tx = txWave(2:2:end);
        I_rx = 2*I_zong - 1;
        Q_rx = 2*Q_zong - 1;

        % 手动绘制穿过原点的黑色十字线
        plot([-1.5 1.5], [0 0], 'k-', 'LineWidth', 1); hold on;
        plot([0 0], [-1.5 1.5], 'k-', 'LineWidth', 1);

        % 绘制发送端星座图 (蓝色圆圈)
        scatter(I_tx, Q_tx, 80, 'bo', 'LineWidth', 1.5); 
        % 绘制接收端星座图 (红色叉号)
        scatter(I_rx, Q_rx, 60, 'rx', 'LineWidth', 1.5);
        
        grid on;
        title('Q P S K 星 座 图', 'FontName', fName, 'FontSize', 12);
        xlabel('I 路 幅 度', 'FontName', fName, 'FontSize', 10); 
        ylabel('Q 路 幅 度', 'FontName', fName, 'FontSize', 10);
        axis([-1.5 1.5 -1.5 1.5]);
        axis square; 
        legend('发 送 端 (理 想)', '接 收 端 (判 决 后)', 'Location', 'northeastoutside');
        hold off;

        % ---- 结果面板更新 ----
        if useHamming
            resStr = { ...
                sprintf('原始: %d 位', M), ...
                sprintf('编码: %d 位', Mmod), ...
                sprintf('信道误码: %d (%.4f)', txErr, txBer), ...
                sprintf('解码误码: %d (%.4f)', decErr, decBer), ...
                sprintf('SNR: %g dB', snr)};
        else
            resStr = { ...
                sprintf('原始: %d 位', M), ...
                sprintf('传输: %d 位', Mmod), ...
                sprintf('信道误码: %d (%.4f)', txErr, txBer), ...
                sprintf('判决误码: %d (%.4f)', decErr, decBer), ...
                sprintf('SNR: %g dB', snr)};
        end
        set(resultText,'String',resStr);

        try
            set(tg,'SelectedTab',tab1);
        catch
        end
    end
end