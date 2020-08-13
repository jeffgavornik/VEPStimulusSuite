function playAlertTone(type,showPlot)
% playAlertTone(type,showPlot)
% Play a predefined audio tone.  Type options are:
%   'NormalCompletion': chirpy bounce
%   'OldCompletion': two-frequency sinusoidal
%   'OldAbort': three quick beeps
%   'Abort': fast modulated tone
%   'Chirp': chirp, sweep up then down
%   'ModulatedSine': sine modulated tone
%   <default>: short buzzer
%   showplot set true also plots the sonic waveform
if nargin == 0
    type = '';
end
if nargin < 2
    showPlot = false;
end
Fs = 2.2255e+004; % default sample rate for MakeBeep
switch lower(type)
    case 'oldcompletion'
        tone1 = MakeBeep(300,0.5,Fs);
        tone2 = MakeBeep(250,0.5,Fs);
        tone = [tone1 tone2 tone1 tone2 tone1 tone2];
        lt = length(tone);
        mask = [linspace(0,1,lt/4) ones(1,lt/2) linspace(1,0,lt/4)];
    case 'new'
        tone1 = MakeBeep(375,0.5,Fs);
        tone2 = MakeBeep(250,0.5,Fs);
        tone3 = MakeBeep(0,0.1,Fs);
        tone = [tone2 tone3 tone2 tone1];
        mask = ones(size(tone));
    case 'normalcompletion'
        t=0:1/Fs:0.5;
        sweep = chirp(t,0,0.5,1250);
        tone = [sweep sweep(end:-1:200) sweep sweep sweep];
        mask = normpdf(1:length(tone),length(tone)/2,length(tone)/7);
        mask = mask/max(mask);
    case 'chirp'
        t=0:1/Fs:0.5;
        sweep = chirp(t,0,0.5,1250);
        tone = [sweep sweep(end:-1:1)];
        mask = normpdf(1:length(tone),length(tone)/2,length(tone)/7);
        mask = mask/max(mask);
    case 'oldabort'
        abort_tone = MakeBeep(500,0.05,Fs);
        space = zeros(1,round(length(abort_tone)/3));
        tone = [abort_tone space abort_tone space abort_tone space];
        mask = ones(size(tone));
    case 'abort'
        duration = 0.3; % s
        modFreq = 20; % Hz
        pureTone = MakeBeep(350,duration,Fs);
        lt = length(pureTone);
        modulation = (1 + sin(linspace(0,duration*modFreq*2*pi,...
            lt)-pi/2))/2;
        tone = pureTone .* modulation(1:lt);
        mask = [linspace(0,1,round(lt/4)) ones(1,round(lt/2)) linspace(1,0,round(lt/4))];
        mask = mask(1:lt);
    case 'modulatedsine'
        duration = 1; % s
        modFreq = 5; % Hz
        pureTone = MakeBeep(350,duration,Fs);
        modulation = (1 + sin(linspace(0,duration*modFreq*2*pi,...
            length(pureTone))-pi/2))/2;
        tone = pureTone .* modulation;
        lt = length(tone);
        mask = [linspace(0,1,lt/4) ones(1,lt/2) linspace(1,0,lt/4)];
    otherwise % default buzzer tone
        duration = 0.5; % s
        freq = 100; % Hz
        tone = sawtooth(freq*2*pi*(0:duration*Fs)/Fs);
        mask = normpdf(1:length(tone),length(tone)/2,length(tone)/7);
        mask = mask/max(mask);
end
tone = tone.*mask;
sound(tone,Fs,16);

if showPlot
    figure(1)
    plot((0:length(tone)-1)/Fs,tone)
    xlabel('t (s)')
    title(['TonePlot: ' type])
end