%% EE5334 Assignment 1 - Objective 1: Telugu speech analysis
% This program analyses selected Telugu vowels from the recorded speech.
% Narrowband and wideband spectrograms are used to study the speech signal.
% Pitch is estimated from harmonic spacing and the average magnitude
% difference function (AMDF). LPC is used to estimate the first three formants.

clc;
clear;
close all;

%% 1. Analysis settings
vowelFile = 'Telugu_Vowels.wav';             % Recording containing the vowel examples
consonantFile = 'Telugu_Consonants.wav';     % Recording containing the consonant examples
task1Words = [1 3 5];                        % Word indices: 1=Amma, 2=Aavu, 3=Illu

minPitch = 60;                               % Lowest expected pitch frequency (Hz)
maxPitch = 350;                              % Highest expected pitch frequency (Hz)
pitchFs = 10000;                             % Sampling rate used for pitch and LPC analysis
pitchFrameDuration = 0.040;                  % Pitch analysis frame length (40 ms)
pitchFrameShift = 0.010;                     % Pitch analysis frame shift (10 ms)

narrowWindowDuration = 0.040;                % Longer window improves frequency resolution
narrowFrameShift = 0.010;                    % Time between narrowband analysis frames
narrowNfft = 8192;                            % FFT length for the narrowband spectrogram

wideWindowDuration = 0.005;                  % Short window improves time resolution
wideFrameShift = 0.001;                      % Time between wideband analysis frames
wideNfft = 2048;                              % FFT length for the wideband spectrogram
wideMaxFrequency = 4000;                     % Highest frequency displayed in the wideband plot

formantFrameDuration = 0.025;                % LPC frame length (25 ms)
formantFrameShift = 0.005;                   % LPC frame shift (5 ms)
formantOrder = 14;                            % Number of LPC coefficients used for the vocal-tract model
preEmphasis = 0.80;                           % Pre-emphasis coefficient for the speech signal

%% 2. Read recordings and prepare signals
[xVowel,Fs] = audioread(vowelFile);           % Read the vowel recording and its sampling rate
[xConsonant,FsConsonant] = audioread(consonantFile); % Read the consonant recording

% Stereo recordings are converted to mono by averaging the channels.
if size(xVowel,2) > 1
    xVowel = mean(xVowel,2);                  % Combine the left and right vowel channels
end
if size(xConsonant,2) > 1
    xConsonant = mean(xConsonant,2);          % Combine the left and right consonant channels
end
xVowel = xVowel(:);                           % Keep the vowel signal as a column vector
xConsonant = xConsonant(:);                   % Keep the consonant signal as a column vector

x10k = resample(xVowel,pitchFs,Fs);           % Resample the vowel recording to 10 kHz
x10k = x10k(:);                               % Keep the resampled signal as a column vector

S = teluguSegments();                         % Load the word names and their time boundaries

% The output directory name is formed from the selected words and vowels.
folderParts = cell(1,numel(task1Words));
for q = 1:numel(task1Words)
    vowelTag = strrep(S.Vowel{task1Words(q)},'/',''); % Remove slashes for a valid folder name
    folderParts{q} = [S.Word{task1Words(q)} '_' vowelTag]; % Combine the word and vowel labels
end
selectionTag = strjoin(folderParts,'_');      % Join all selected word labels into one name
outputFolder = ['Task1_Results_' selectionTag]; % Output folder changes when task1Words changes
if ~isfolder(outputFolder)
    mkdir(outputFolder);                      % Create the folder for this selection of words
end

fprintf('Task 1 selected words: %s\n',strjoin(S.Word(task1Words),', '));
fprintf('PNG output folder: %s\n',outputFolder);

%% 3. Plot the complete recordings
fig = figure('Name','Overall recordings','Color','w');
tiledlayout(2,1,'TileSpacing','compact');

nexttile;
plot((0:numel(xVowel)-1)/Fs,xVowel,'k');       % Plot the complete vowel recording against time
xlabel('Time (s)');
ylabel('Amplitude');
title('Telugu vowel recording');
grid on;

nexttile;
plot((0:numel(xConsonant)-1)/FsConsonant,xConsonant,'k'); % Plot the complete consonant recording
xlabel('Time (s)');
ylabel('Amplitude');
title('Telugu consonant recording');
grid on;

saveFigure(fig,fullfile(outputFolder,'00_Overall_Recordings.png'));

%% 4. Analyse each selected vowel
for q = 1:numel(task1Words)
    wordNo = task1Words(q);                   % Index of the current word in the segment table
    wordName = S.Word{wordNo};                % Name used in plot titles and image filenames
    vowelName = S.Vowel{wordNo};              % Vowel symbol used in plot titles
    vowelTag = strrep(vowelName,'/','');       % Vowel label without slashes for the filename
    fileTag = [wordName '_' vowelTag];         % Prefix shared by this word's plot files
    vowelStart = S.VowelStart(wordNo);         % Beginning of the vowel in seconds
    vowelEnd = S.VowelEnd(wordNo);             % End of the vowel in seconds

    fprintf('\nProcessing %s (%s)\n',wordName,vowelName);

    % A short amount of neighbouring speech is included in the spectrograms.
    contextStart = max(0,S.WordStart(wordNo)-0.08); % Context start before the word
    contextEnd = min(numel(xVowel)/Fs,S.WordEnd(wordNo)+0.08); % Context end after the word
    contextFirst = floor(contextStart*Fs)+1;   % Convert context start time to a sample index
    contextLast = min(numel(xVowel),floor(contextEnd*Fs)); % Convert context end time to a sample index
    wordSignal = xVowel(contextFirst:contextLast); % Extract the word and its surrounding speech

    %% 4A. Narrowband spectrogram
    narrowLength = round(narrowWindowDuration*Fs); % Number of samples in a narrowband frame
    narrowHop = round(narrowFrameShift*Fs);         % Number of samples between frames
    [Z,F,T] = spectrogram(wordSignal,hamming(narrowLength,'periodic'), ...
        narrowLength-narrowHop,narrowNfft,Fs);       % Calculate the short-time Fourier transform
    narrowDB = 20*log10(abs(Z)+eps);                % Convert the magnitude spectrum to decibels
    narrowDB = narrowDB-max(narrowDB(:));           % Reference the strongest component to 0 dB

    fig = figure('Name',['Narrowband - ' wordName],'Color','w');
    imagesc(contextStart+T,F,narrowDB);             % Display frequency against the actual recording time
    axis xy;
    xlim([contextStart contextEnd]);
    ylim([0 4000]);
    clim([-60 0]);
    colormap(gca,'jet');
    colorbar;
    hold on;
    xline(vowelStart,'w--','LineWidth',1.2,'HandleVisibility','off'); % Mark the vowel beginning
    xline(vowelEnd,'w--','LineWidth',1.2,'HandleVisibility','off');   % Mark the vowel ending
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(['Narrowband spectrogram - ' wordName ' (' vowelName ')']);
    saveFigure(fig,fullfile(outputFolder,['01_' fileTag '_Narrowband.png']));

    %% 4B. Extract the vowel for pitch analysis
    vowelFirst = floor(vowelStart*pitchFs)+1;        % First sample of the vowel at 10 kHz
    vowelLast = floor(vowelEnd*pitchFs);             % Last sample of the vowel at 10 kHz
    vowelSignal = x10k(vowelFirst:vowelLast);        % Isolate the selected vowel

    % AMDF is calculated over overlapping frames so pitch is not taken from
    % only one short part of the vowel.
    [amdfPitch,amdfPitchFrames,amdfLagMs,amdfMean] = ...
        estimateAMDFTrack(vowelSignal,pitchFs,minPitch,maxPitch, ...
        pitchFrameDuration,pitchFrameShift);

    % The harmonic estimate uses repeated spacing between spectral peaks.
    harmonicPitch = estimateHarmonicSpacing(vowelSignal,pitchFs, ...
        minPitch,maxPitch,pitchFrameDuration,pitchFrameShift);

    %% 4C. Average spectrum and harmonic spacing plot
    [averageMagnitude,frequency] = averageSpectrum(vowelSignal,pitchFs, ...
        pitchFrameDuration,pitchFrameShift,32768);  % Average spectra from the vowel frames
    spectrumDB = 20*log10(averageMagnitude+eps);    % Convert the averaged spectrum to decibels
    spectrumDB = spectrumDB-max(spectrumDB);        % Normalize the largest spectral peak to 0 dB

    fig = figure('Name',['Harmonic spectrum - ' wordName],'Color','w');
    visible = frequency<=2500;                      % Display the lower speech-frequency region
    plot(frequency(visible),spectrumDB(visible),'b','LineWidth',1.2);
    hold on;
    if isfinite(harmonicPitch)
        for h = 1:floor(2500/harmonicPitch)
            xline(h*harmonicPitch,'g--','HandleVisibility','off'); % Mark integer multiples of the estimated F0
        end
    end
    if isfinite(amdfPitch)
        xline(amdfPitch,'r:','LineWidth',1.5,'DisplayName','AMDF F0'); % Show the AMDF estimate for comparison
    end
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB, normalized)');
    title(['Average harmonic spectrum - ' wordName ' (' vowelName ')']);
    xlim([0 2500]);
    ylim([-60 5]);
    grid on;
    if isfinite(amdfPitch)
        legend('Spectrum','AMDF F0','Location','northeast');
    end
    saveFigure(fig,fullfile(outputFolder,['02_' fileTag '_Harmonic_Spectrum.png']));

    %% 4D. Average magnitude difference function
    fig = figure('Name',['AMDF - ' wordName],'Color','w');
    plot(amdfLagMs,amdfMean,'b','LineWidth',1.3); % Plot the AMDF averaged over the vowel frames
    hold on;
    if isfinite(amdfPitch)
        xline(1000/amdfPitch,'r--','LineWidth',1.3, ...
            'DisplayName',sprintf('Selected period = %.2f ms',1000/amdfPitch)); % Mark the selected pitch period
        legend('AMDF averaged across frames','Selected period','Location','best');
    end
    xlabel('Delay (ms)');
    ylabel('Normalized AMDF');
    title(['AMDF pitch estimation - ' wordName ' (' vowelName ')']);
    grid on;
    saveFigure(fig,fullfile(outputFolder,['03_' fileTag '_AMDF.png']));

    %% 4E. Wideband spectrogram
    wideLength = round(wideWindowDuration*Fs);       % Number of samples in a wideband frame
    wideHop = round(wideFrameShift*Fs);              % Number of samples between wideband frames
    [Zw,Fw,Tw] = spectrogram(wordSignal,hamming(wideLength,'periodic'), ...
        wideLength-wideHop,wideNfft,Fs);              % Calculate the wideband short-time spectrum
    wideDB = 20*log10(abs(Zw)+eps);                  % Convert the wideband magnitude to decibels
    wideDB = wideDB-max(wideDB(:));                  % Normalize the strongest component to 0 dB

    %% 4F. LPC formant tracking
    [formantTimes,formants] = estimateFormantsLPC( ...
        x10k,pitchFs,vowelName,vowelStart,vowelEnd, ...
        formantFrameDuration,formantFrameShift,formantOrder,preEmphasis);

    % Display the formant tracks over the wideband spectrogram.
    fig = figure('Name',['Wideband formants - ' wordName],'Color','w');
    imagesc(contextStart+Tw,Fw,wideDB);
    axis xy;
    xlim([max(contextStart,vowelStart-0.025) min(contextEnd,vowelEnd+0.025)]);
    ylim([0 wideMaxFrequency]);
    clim([-60 0]);
    colormap(gca,'jet');
    colorbar;
    hold on;
    xline(vowelStart,'w--','LineWidth',1.2,'HandleVisibility','off'); % Mark the start of the vowel
    xline(vowelEnd,'w--','LineWidth',1.2,'HandleVisibility','off');   % Mark the end of the vowel
    plot(formantTimes,formants(:,1),'y.-','LineWidth',1.7,'MarkerSize',10,'DisplayName','F1'); % First formant track
    plot(formantTimes,formants(:,2),'c.-','LineWidth',1.7,'MarkerSize',10,'DisplayName','F2'); % Second formant track
    plot(formantTimes,formants(:,3),'m.-','LineWidth',1.7,'MarkerSize',10,'DisplayName','F3'); % Third formant track
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(['Wideband spectrogram with LPC formant contours - ' wordName ' (' vowelName ')']);
    legend('Location','northeast');
    grid on;
    saveFigure(fig,fullfile(outputFolder,['04_' fileTag '_Wideband_Formants.png']));

    %% 4G. Display the estimated pitch and formants
    % The middle part of the vowel is used for the average formants because
    % the beginning and ending portions contain transitions to other sounds.
    stableFrames = formantTimes>=vowelStart+0.15*(vowelEnd-vowelStart) & ...
        formantTimes<=vowelEnd-0.15*(vowelEnd-vowelStart); % Select frames away from the vowel boundaries
    validFrames = stableFrames & all(isfinite(formants),2); % Keep frames with all three formant estimates

    fprintf('  Harmonic-spacing pitch : %.2f Hz\n',harmonicPitch);
    fprintf('  AMDF pitch             : %.2f Hz\n',amdfPitch);
    if any(validFrames)
        averageFormants = median(formants(validFrames,:),1); % Median reduces the effect of occasional LPC outliers
        fprintf('  F1                      : %.2f Hz\n',averageFormants(1));
        fprintf('  F2                      : %.2f Hz\n',averageFormants(2));
        fprintf('  F3                      : %.2f Hz\n',averageFormants(3));
    end
end

fprintf('\nAll PNG plots have been saved in: %s\n',outputFolder);

%% =========================== LOCAL FUNCTIONS ===========================

function [f0Median,f0Frames,lagMs,amdfMean] = estimateAMDFTrack( ...
    x,Fs,minPitch,maxPitch,frameDuration,frameShift)
% Calculate normalized AMDF curves for overlapping frames and select a
% likely pitch period from the local minima in the permitted delay range.

x = x(:);
frameLength = round(frameDuration*Fs);       % Frame length in samples
hop = round(frameShift*Fs);                 % Frame shift in samples
minLag = round(Fs/maxPitch);                % Shortest period allowed by the pitch range
maxLag = round(Fs/minPitch);                % Longest period allowed by the pitch range
lags = minLag:maxLag;                       % Candidate pitch periods in samples
numberOfFrames = floor((numel(x)-frameLength)/hop)+1; % Number of complete analysis frames
allAMDF = zeros(numberOfFrames,numel(lags)); % Storage for the AMDF of every frame
f0Frames = nan(numberOfFrames,1);           % Framewise pitch estimates

for k = 1:numberOfFrames
    firstSample = 1+(k-1)*hop;              % First sample of the current frame
    frame = x(firstSample:firstSample+frameLength-1); % Extract the current frame
    frame = frame-mean(frame);              % Remove the frame's DC component
    frame = frame.*hamming(frameLength,'periodic'); % Reduce discontinuities at the frame edges

    amdf = zeros(size(lags));
    correlation = zeros(size(lags));
    for j = 1:numel(lags)
        delay = lags(j);                    % Current delay in samples
        firstPart = frame(1:end-delay);     % Original frame without its last delay samples
        secondPart = frame(1+delay:end);    % Delayed frame without its first delay samples
        amdf(j) = mean(abs(firstPart-secondPart)) / ...
            (mean(abs(firstPart))+mean(abs(secondPart))+eps); % Normalized average difference
        correlation(j) = sum(firstPart.*secondPart) / ...
            (sqrt(sum(firstPart.^2)*sum(secondPart.^2))+eps); % Correlation supports period selection
    end
    allAMDF(k,:) = amdf;                    % Store this frame's AMDF curve

    % A pitch period appears as a local AMDF minimum. Correlation helps
    % distinguish the fundamental period from a multiple of that period.
    localMinima = find(amdf(2:end-1)<=amdf(1:end-2) & ...
        amdf(2:end-1)<=amdf(3:end))+1;       % Indices of local AMDF minima
    if isempty(localMinima)
        [~,selectedIndex] = min(amdf);       % Use the lowest AMDF value if no local minimum is found
    else
        score = correlation(localMinima)-0.20*amdf(localMinima) ...
            -0.03*(lags(localMinima)/maxLag); % Prefer periodic matches at shorter plausible delays
        [~,bestLocal] = max(score);
        selectedIndex = localMinima(bestLocal); % Index of the selected pitch-period minimum
    end

    refinedLag = lags(selectedIndex);         % Initial pitch period in samples
    if selectedIndex>1 && selectedIndex<numel(amdf)
        leftValue = amdf(selectedIndex-1);    % AMDF value before the selected minimum
        centreValue = amdf(selectedIndex);    % AMDF value at the selected minimum
        rightValue = amdf(selectedIndex+1);   % AMDF value after the selected minimum
        denominator = leftValue-2*centreValue+rightValue;
        if abs(denominator)>eps
            offset = 0.5*(leftValue-rightValue)/denominator; % Parabolic interpolation offset
            refinedLag = refinedLag+max(-0.5,min(0.5,offset)); % Refine the period to a fraction of a sample
        end
    end
    f0Frames(k) = Fs/refinedLag;             % Convert the period in samples to frequency in Hz

    if correlation(selectedIndex)<0.15 || amdf(selectedIndex)>0.75
        f0Frames(k) = NaN;                    % Exclude a frame with weak periodicity
    end
end

f0Median = median(f0Frames,'omitnan');        % Median pitch across the voiced frames
amdfMean = mean(allAMDF,1);                  % Average the AMDF curves over all frames
lagMs = 1000*lags/Fs;                        % Express the delay axis in milliseconds
end

function f0 = estimateHarmonicSpacing(x,Fs,minPitch,maxPitch,frameDuration,frameShift)
% Estimate F0 by finding a fundamental spacing that explains the detected
% spectral-peak gaps as integer multiples of that spacing.

[averageMagnitude,frequency] = averageSpectrum(x,Fs,frameDuration,frameShift,32768); % Average the vowel spectra
search = frequency>=minPitch & frequency<=2500; % Frequency range used for harmonic peaks
spectrumDB = 20*log10(averageMagnitude(search)+eps); % Convert spectrum to decibels
spectrumDB = spectrumDB-max(spectrumDB);      % Normalize the strongest peak to 0 dB
searchFrequency = frequency(search);

[peakHeight,peakFrequency] = findpeaks(spectrumDB,searchFrequency, ...
    'MinPeakDistance',0.65*minPitch,'MinPeakProminence',3); % Detect prominent harmonic peaks
keepPeaks = peakHeight>-35;                    % Retain peaks close enough to the strongest component
peakFrequency = peakFrequency(keepPeaks);
peakHeight = peakHeight(keepPeaks);
peakGaps = diff(peakFrequency);                % Gaps between adjacent detected spectral peaks
peakWeights = 10.^(peakHeight(2:end)/20);      % Give stronger peaks more influence
peakWeights = peakWeights/(max(peakWeights)+eps); % Normalize the peak weights
candidateF0 = minPitch:0.25:maxPitch;          % Fundamental frequencies to test
scores = zeros(size(candidateF0));

for k = 1:numel(candidateF0)
    trialF0 = candidateF0(k);                  % Current candidate fundamental frequency
    multiples = round(peakGaps/trialF0);       % Number of fundamental periods in each peak gap
    gapError = abs(peakGaps-multiples*trialF0); % Difference from an integer harmonic spacing
    matches = multiples>=1 & multiples<=4 & gapError<=max(12,0.07*trialF0); % Accept near-integer gaps
    scores(k) = sum(peakWeights(matches)./multiples(matches)); % Score the harmonic-spacing agreement
end

[bestScore,bestIndex] = max(scores);
if bestScore>0
    f0 = candidateF0(bestIndex);               % Candidate with the strongest harmonic-spacing agreement
else
    f0 = NaN;
end
end

function [averageMagnitude,frequency] = averageSpectrum(x,Fs,frameDuration,frameShift,nfft)
% Average the magnitude spectra of overlapping frames from the selected vowel.

x = x(:);
frameLength = round(frameDuration*Fs);         % Number of samples in each spectrum frame
hop = round(frameShift*Fs);                   % Number of samples between consecutive frames
frameStarts = 1:hop:(numel(x)-frameLength+1);  % Starting sample of every complete frame
window = hamming(frameLength,'periodic');     % Hamming window reduces spectral leakage
spectrumSum = zeros(nfft/2+1,1);               % Accumulator for the positive-frequency spectra

for k = 1:numel(frameStarts)
    frame = x(frameStarts(k):frameStarts(k)+frameLength-1); % Extract the current frame
    frame = frame-mean(frame);                 % Remove DC before calculating the spectrum
    frameSpectrum = fft(frame.*window,nfft);   % Calculate the windowed frame spectrum
    spectrumSum = spectrumSum+abs(frameSpectrum(1:nfft/2+1)); % Add its positive-frequency magnitude
end

averageMagnitude = spectrumSum/numel(frameStarts); % Average the magnitude spectra
frequency = (0:nfft/2)'*Fs/nfft;              % Frequency corresponding to each FFT bin
end

function [times,formants] = estimateFormantsLPC(x,Fs,vowelName,vowelStart,vowelEnd, ...
    frameDuration,frameShift,order,preEmphasis)
% Estimate the vocal-tract resonances from LPC poles in overlapping frames.
% Pole bandwidths, vowel ranges and continuity are used to select F1-F3.

x = x(:);
xPre = filter([1 -preEmphasis],1,x);          % Pre-emphasis increases the relative high-frequency energy
frameLength = round(frameDuration*Fs);        % LPC frame length in samples

% Keep the frames within the vowel so the formant tracks do not include
% the transitions from the neighbouring consonants.
firstStart = vowelStart+0.10*(vowelEnd-vowelStart); % Start slightly inside the vowel
lastStart = vowelEnd-0.10*(vowelEnd-vowelStart)-frameDuration; % Last complete frame start
frameStarts = firstStart:frameShift:lastStart;
if isempty(frameStarts)
    frameStarts = (vowelStart+vowelEnd-frameDuration)/2; % Use one centred frame for a short vowel
end

times = frameStarts(:)+frameDuration/2;      % Centre time of each LPC frame
formants = nan(numel(times),3);              % Columns store F1, F2 and F3
window = hamming(frameLength,'periodic');    % Window applied before LPC analysis
[f1Range,f2Range,f3Range,target] = vowelFormantRanges(vowelName); % Expected frequency regions for this vowel
previous = [NaN NaN NaN];                    % Previous frame's formants for continuity

for k = 1:numel(frameStarts)
    firstSample = floor(frameStarts(k)*Fs)+1; % First sample of the current LPC frame
    lastSample = firstSample+frameLength-1;   % Last sample of the current LPC frame
    frame = xPre(firstSample:lastSample);     % Extract the pre-emphasized speech frame
    frame = frame-mean(frame);                % Remove any remaining DC component
    frame = frame.*window;                   % Apply the analysis window
    coefficients = lpc(frame,order);         % Fit the all-pole vocal-tract model
    poles = roots(coefficients);              % Roots of the LPC polynomial are its poles
    poles = poles(imag(poles)>0);             % Use one pole from each complex-conjugate pair
    radius = abs(poles);                      % Pole radius controls resonance bandwidth
    poleFrequency = angle(poles)*Fs/(2*pi);   % Pole angle converted to frequency in Hz
    poleBandwidth = -Fs/pi*log(max(radius,eps)); % Estimate each pole's bandwidth

    valid = radius>0.75 & radius<1 & poleBandwidth>=40 & ...
        poleBandwidth<=500 & poleFrequency>=200 & poleFrequency<=min(4500,Fs/2-100); % Keep plausible resonances
    candidates = [poleFrequency(valid),poleBandwidth(valid)]; % Candidate frequency and bandwidth pairs

    f1Candidates = candidates(candidates(:,1)>=f1Range(1) & candidates(:,1)<=f1Range(2),:);
    f2Candidates = candidates(candidates(:,1)>=f2Range(1) & candidates(:,1)<=f2Range(2),:);
    f3Candidates = candidates(candidates(:,1)>=f3Range(1) & candidates(:,1)<=f3Range(2),:);

    bestScore = Inf;
    bestFormants = [NaN NaN NaN];
    for i = 1:size(f1Candidates,1)
        for j = 1:size(f2Candidates,1)
            if f2Candidates(j,1)<=f1Candidates(i,1)+150
                continue;                     % F2 must be above F1
            end
            for m = 1:size(f3Candidates,1)
                if f3Candidates(m,1)<=f2Candidates(j,1)+200
                    continue;                 % F3 must be above F2
                end
                trial = [f1Candidates(i,1),f2Candidates(j,1),f3Candidates(m,1)]; % Ordered F1-F2-F3 candidate
                bandwidthPenalty = sum([f1Candidates(i,2),f2Candidates(j,2),f3Candidates(m,2)])/500; % Prefer clearer resonances
                rangeScale = [diff(f1Range),diff(f2Range),diff(f3Range)]; % Scale each formant range
                targetPenalty = 0.20*sum(((trial-target)./rangeScale).^2); % Keep candidates within the vowel's broad frequency pattern
                continuityPenalty = 0;
                if all(isfinite(previous))
                    continuityPenalty = 0.35*sum(abs(trial-previous)./[300 500 700]); % Discourage sudden frame-to-frame jumps
                end
                score = bandwidthPenalty+targetPenalty+continuityPenalty; % Combined score for the candidate formant set
                if score<bestScore
                    bestScore = score;
                    bestFormants = trial;       % Store the lowest-scoring ordered formant set
                end
            end
        end
    end

    if all(isfinite(bestFormants))
        formants(k,:) = bestFormants;           % Store F1, F2 and F3 for this frame
        previous = bestFormants;                % Use this frame to guide the next frame's selection
    end
end
end

function [f1Range,f2Range,f3Range,target] = vowelFormantRanges(vowelName)
% These broad ranges guide pole assignment; they are not fixed measured values.
switch vowelName
    case {'/a/','/aa/','/au/'}
        f1Range = [350 1100]; f2Range = [850 2400]; f3Range = [1800 4300];
        target = [750 1450 2700];
    case {'/i/','/ii/'}
        f1Range = [200 800]; f2Range = [1500 3600]; f3Range = [2300 4500];
        target = [420 2450 3150];
    case {'/u/','/uu/'}
        f1Range = [200 850]; f2Range = [600 1800]; f3Range = [1700 3600];
        target = [430 1050 2600];
    case {'/e/','/ee/'}
        f1Range = [200 900]; f2Range = [1200 3200]; f3Range = [2200 4300];
        target = [500 2050 3000];
    case {'/o/','/oo/'}
        f1Range = [200 950]; f2Range = [600 1900]; f3Range = [1700 3800];
        target = [520 1150 2700];
    otherwise
        f1Range = [200 1100]; f2Range = [700 3500]; f3Range = [1700 4500];
        target = [600 1800 2900];
end
end

function saveFigure(fig,fileName)
% Export a figure as a PNG image and close it after saving.
exportgraphics(fig,fileName,'Resolution',200); % Save the figure without the axes toolbar
close(fig);
end

function S = teluguSegments()
% Word and vowel boundaries measured from the Telugu vowel recording (seconds).
S.Word = {'Amma';'Aavu';'Illu';'Eega';'Uduta';'Ooyala';'Eluka';'Eenugu'; ...
    'Aidu';'Onte';'Oda';'Aushadham'};
S.Vowel = {'/a/';'/aa/';'/i/';'/ii/';'/u/';'/uu/';'/e/';'/ee/'; ...
    '/ai/';'/o/';'/oo/';'/au/'};
S.WordStart = [1.74;3.08;4.76;6.55;8.19;9.92;11.62;13.51;15.32;17.13;18.88;20.63];
S.WordEnd = [2.44;3.86;5.47;7.23;8.88;10.57;12.32;14.24;16.00;17.78;19.50;21.36];
S.VowelStart = [1.77;3.14;4.83;6.58;8.22;9.97;11.66;13.55;15.38;17.16;18.91;20.65];
S.VowelEnd = [1.94;3.47;5.00;6.87;8.39;10.27;11.84;13.79;15.63;17.44;19.20;20.90];
end