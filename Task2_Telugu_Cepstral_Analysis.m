%% EE5334 Assignment 1 - Objective 2: Cepstral analysis
% This program estimates pitch and the first three formants using the real
% cepstrum of a selected Telugu vowel. Eight consecutive frames are analysed.
% Low-quefrency liftering is used to obtain the smoothed spectral envelope.

clc;
clear;
close all;

%% 1. Analysis settings
vowelFile = 'Telugu_Vowels.wav';              % Recording containing the Telugu vowel examples
wordNo = 5;                                   % Selected word index: 1=Amma, 2=Aavu, 3=Illu, etc.

analysisFs = 10000;                           % Sampling rate used for cepstral analysis
frameDuration = 0.025;                        % Length of each analysis frame (25 ms)
frameShift = 0.005;                           % Shift between consecutive frames (5 ms)
numberOfFrames = 8;                           % Eight consecutive frames are used for the averages
nfft = 8192;                                  % FFT length used to calculate the spectrum and cepstrum
preEmphasis = 0.80;                           % Pre-emphasis coefficient for the speech signal
lifterCutoff = 0.0015;                        % Low-quefrency cutoff used for spectral-envelope smoothing
minPitch = 60;                                % Lowest expected pitch frequency (Hz)
maxPitch = 350;                               % Highest expected pitch frequency (Hz)
minF1F2Gap = 300;                             % Minimum frequency gap between F1 and F2 (Hz)
minF2F3Gap = 450;                             % Minimum frequency gap between F2 and F3 (Hz)

%% 2. Read the vowel recording
[xVowel,Fs] = audioread(vowelFile);            % Read the speech recording and its sampling rate

if size(xVowel,2)>1
    xVowel = mean(xVowel,2);                  % Convert stereo speech to mono by averaging the channels
end

xVowel = xVowel(:);                           % Keep the speech signal as a column vector
x10k = resample(xVowel,analysisFs,Fs);         % Resample the recording to 10 kHz
xPreEmphasis = filter([1 -preEmphasis],1,x10k); % Emphasize higher-frequency speech components

S = teluguSegments();                         % Load word names and vowel time boundaries
wordName = S.Word{wordNo};                    % Name of the selected word
vowelName = S.Vowel{wordNo};                  % Vowel symbol associated with the word
vowelTag = strrep(vowelName,'/','');          % Remove slashes for filenames
fileTag = [wordName '_' vowelTag];            % Prefix used for all plots from this vowel
vowelStart = S.VowelStart(wordNo);             % Start of the vowel in seconds
vowelEnd = S.VowelEnd(wordNo);                 % End of the vowel in seconds

outputFolder = ['Task2_' wordName];            % Folder name follows the selected word
if ~isfolder(outputFolder)
    mkdir(outputFolder);                      % Create the folder for this vowel's plots
end

fprintf('Task 2 selected vowel: %s (%s)\n',wordName,vowelName);
fprintf('PNG output folder: %s\n',outputFolder);

%% 3. Extract the selected vowel
firstVowelSample = floor(vowelStart*analysisFs)+1; % First sample of the vowel at 10 kHz
lastVowelSample = floor(vowelEnd*analysisFs);      % Last sample of the vowel at 10 kHz

vowelSignal = x10k(firstVowelSample:lastVowelSample); % Original resampled signal for the waveform plot
vowelPreEmphasis = xPreEmphasis(firstVowelSample:lastVowelSample); % Pre-emphasized segment for cepstral analysis

segmentStartTime = (firstVowelSample-1)/analysisFs; % Actual time of the first extracted sample

%% 4. Select eight consecutive frames from the high-energy vowel region
frameLength = round(frameDuration*analysisFs); % Number of samples in one analysis frame
hopLength = round(frameShift*analysisFs);     % Number of samples between consecutive frame starts

frameStarts = 1:hopLength:(numel(vowelSignal)-frameLength+1); % Possible frame start positions

% Frame energy is measured on the original waveform so that the selected
% block follows the strong part of the vowel in the time-domain signal.
frameEnergy = zeros(numel(frameStarts),1);     % Store mean-square energy for every possible frame

for k = 1:numel(frameStarts)
    firstSample = frameStarts(k);              % First sample of the current candidate frame
    frame = vowelSignal(firstSample:firstSample+frameLength-1); % Extract the candidate frame
    frameEnergy(k) = mean(frame.^2);           % Mean-square value represents the frame energy
end

% The average energy of each possible eight-frame block is compared.
blockEnergy = conv(frameEnergy,ones(numberOfFrames,1)/numberOfFrames,'valid'); % Average energy of each consecutive block

[~,firstFrame] = max(blockEnergy);             % Beginning of the block with the highest average energy
chosenStarts = frameStarts(firstFrame:firstFrame+numberOfFrames-1); % Eight consecutive frame positions

frameWindow = hamming(frameLength,'periodic'); % Hamming window reduces discontinuities at frame edges

frequency = (0:nfft/2)'*analysisFs/nfft;       % Frequency axis for the positive-frequency spectrum
quefrencyMs = (0:nfft/2)'/analysisFs*1000;     % Quefrency axis in milliseconds

pitchFrames = zeros(numberOfFrames,1);         % Pitch estimate from each selected frame
formantFrames = zeros(numberOfFrames,3);       % Columns hold F1, F2 and F3 for each frame
frameTimes = zeros(numberOfFrames,1);          % Centre time of every selected frame

smoothedSpectra = zeros(nfft/2+1,numberOfFrames); % Cepstrally smoothed spectrum for every frame
cepstralFrames = zeros(nfft/2+1,numberOfFrames); % Positive-quefrency cepstral sequence for every frame

%% 5. Cepstral analysis of the selected frames
for k = 1:numberOfFrames

    firstSample = chosenStarts(k);              % First sample of the current selected frame
    lastSample = firstSample+frameLength-1;     % Last sample of the current selected frame

    frame = vowelPreEmphasis(firstSample:lastSample); % Extract the pre-emphasized analysis frame
    frame = frame-mean(frame);                  % Remove the frame's DC component
    frame = frame.*frameWindow;                 % Apply the Hamming window before the FFT

    frameTimes(k) = segmentStartTime+(firstSample-1+(frameLength-1)/2)/analysisFs; % Centre time in the original recording

    %% 5A. Real cepstrum and pitch estimation

    frameSpectrum = fft(frame,nfft);            % Transform the speech frame into the frequency domain
    logMagnitude = log(abs(frameSpectrum)+eps); % Log magnitude converts spectral multiplication into addition
    cepstrum = real(ifft(logMagnitude));        % Inverse FFT of log magnitude gives the real cepstrum

    minLag = round(analysisFs/maxPitch);         % Shortest expected pitch period in samples
    maxLag = round(analysisFs/minPitch);         % Longest expected pitch period in samples

    pitchIndices = (minLag:maxLag)+1;            % Convert pitch-period samples to MATLAB indices

    [~,peakPosition] = max(cepstrum(pitchIndices)); % Find the strongest cepstral peak in the pitch range
    peakIndex = pitchIndices(peakPosition);      % Index of the selected pitch peak
    pitchLag = peakIndex-1;                     % Convert the index back to a quefrency in samples

    % Parabolic interpolation refines the cepstral peak location between samples.
    leftValue = cepstrum(peakIndex-1);           % Cepstral value before the peak
    centreValue = cepstrum(peakIndex);           % Cepstral value at the peak
    rightValue = cepstrum(peakIndex+1);          % Cepstral value after the peak

    denominator = leftValue-2*centreValue+rightValue; % Curvature around the selected peak

    if abs(denominator)>eps
        offset = 0.5*(leftValue-rightValue)/denominator; % Sub-sample peak correction
        pitchLag = pitchLag+max(-0.5,min(0.5,offset)); % Refined pitch period in samples
    end

    pitchFrames(k) = analysisFs/pitchLag;        % Convert the cepstral period into fundamental frequency

    %% 5B. Cepstral liftering and spectral-envelope calculation

    cutoffSamples = round(lifterCutoff*analysisFs); % Number of low-quefrency samples retained by the lifter

    smoothCepstrum = zeros(size(cepstrum));      % Start with a zero cepstral sequence

    smoothCepstrum(1:cutoffSamples+1) = cepstrum(1:cutoffSamples+1); % Retain low positive quefrencies
    smoothCepstrum(end-cutoffSamples+1:end) = cepstrum(end-cutoffSamples+1:end); % Retain matching negative quefrencies

    logEnvelope = real(fft(smoothCepstrum));    % Transform the liftered cepstrum back to the log-spectrum domain
    envelope = exp(logEnvelope(1:nfft/2+1));    % Convert the smoothed log spectrum into magnitude

    envelopeDB = 20*log10(envelope+eps);        % Express the smoothed envelope in decibels
    envelopeDB = envelopeDB-max(envelopeDB);   % Normalize the largest envelope value to 0 dB

    smoothedSpectra(:,k) = envelopeDB;          % Store the smoothed spectrum for this frame
    cepstralFrames(:,k) = cepstrum(1:nfft/2+1); % Store the positive-quefrency part of the real cepstrum

    %% 5C. Estimate the first three formants from the smoothed envelope

    [f1Band,f2Band,f3Band] = formantBands(vowelName); % Frequency ranges for the selected vowel

    f1 = findBandPeak(frequency,envelopeDB,f1Band(1),f1Band(2)); % First strong envelope peak in the F1 range

    % A frequency gap is maintained above F1 before searching for F2.
    f2Lower = max(f2Band(1),f1+minF1F2Gap); % Lower limit of the F2 search region
    f2 = findBandPeak(frequency,envelopeDB,f2Lower,f2Band(2)); % Select F2 from the allowed frequency region

    % A wider gap is maintained above F2 before searching for F3.
    f3Lower = max(f3Band(1),f2+minF2F3Gap); % Lower limit of the F3 search region
    f3 = findBandPeak(frequency,envelopeDB,f3Lower,f3Band(2)); % Select F3 away from the F2 peak

    formantFrames(k,:) = [f1 f2 f3];           % Store the three formant frequencies for this frame

end

%% 6. Calculate average pitch and formant frequencies
averagePitch = mean(pitchFrames);              % Average fundamental frequency across the eight frames
averageFormants = mean(formantFrames,1);       % Average F1, F2 and F3 across the same frames

fprintf('\nAverage values from %d consecutive frames\n',numberOfFrames);
fprintf('Average pitch : %.2f Hz\n',averagePitch);
fprintf('Average F1    : %.2f Hz\n',averageFormants(1));
fprintf('Average F2    : %.2f Hz\n',averageFormants(2));
fprintf('Average F3    : %.2f Hz\n',averageFormants(3));

fprintf('\nFramewise estimates\n');

for k = 1:numberOfFrames
    fprintf('Frame %d at %.3f s: F0 = %.2f Hz, F1 = %.1f Hz, F2 = %.1f Hz, F3 = %.1f Hz\n', ...
        k,frameTimes(k),pitchFrames(k),formantFrames(k,1),formantFrames(k,2),formantFrames(k,3));
end

%% 7. Plot the selected vowel and the eight frame positions
fig = figure('Name','Selected vowel frames','Color','w');

timeAxis = segmentStartTime+(0:numel(vowelSignal)-1)/analysisFs; % Time axis for the extracted vowel waveform

plot(timeAxis,vowelSignal,'k','LineWidth',1);
hold on;

for k = 1:numberOfFrames
    xline(frameTimes(k),'r--','LineWidth',0.9,'HandleVisibility','off'); % Mark the centre of each analysis frame
end

xlabel('Time (s)');
ylabel('Amplitude');
title([wordName ' (' vowelName '): eight frames used for cepstral analysis']);
grid on;

saveFigure(fig,fullfile(outputFolder,['01_' fileTag '_Selected_Vowel_Frames.png']));

%% 8. Plot the framewise cepstrally smoothed spectra
fig = figure('Name','Cepstrally smoothed spectra','Color','w');
tiledlayout(2,4,'TileSpacing','compact','Padding','compact');

for k = 1:numberOfFrames
    nexttile;

    plot(frequency,smoothedSpectra(:,k),'b','LineWidth',1.1); % Smoothed spectral envelope for this frame
    hold on;

    xline(formantFrames(k,1),'r--','LineWidth',1.0); % Red marker indicates F1
    xline(formantFrames(k,2),'g--','LineWidth',1.0); % Green marker indicates F2
    xline(formantFrames(k,3),'m--','LineWidth',1.0); % Magenta marker indicates F3

    xlim([0 4000]);
    ylim([-35 3]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    title(sprintf('Frame %d, %.3f s',k,frameTimes(k)));
    grid on;
end

sgtitle(['Cepstrally smoothed spectra - ' wordName ' (' vowelName ')']);

saveFigure(fig,fullfile(outputFolder,['02_' fileTag '_Cepstrally_Smoothed_Spectra.png']));

%% 9. Plot the framewise cepstral sequences
fig = figure('Name','Cepstral sequences','Color','w');
tiledlayout(2,4,'TileSpacing','compact','Padding','compact');

for k = 1:numberOfFrames
    nexttile;

    plot(quefrencyMs,cepstralFrames(:,k),'b','LineWidth',1.1); % Real cepstrum for this frame
    hold on;

    pitchQuefrencyMs = 1000/pitchFrames(k);    % Pitch period expressed in milliseconds
    xline(pitchQuefrencyMs,'r--','LineWidth',1.0); % Mark the cepstral pitch peak

    xlim([0 20]);
    xlabel('Quefrency (ms)');
    ylabel('Cepstral value');
    title(sprintf('Frame %d, %.3f s',k,frameTimes(k)));
    grid on;
end

sgtitle(['Real cepstral sequences - ' wordName ' (' vowelName ')']);

saveFigure(fig,fullfile(outputFolder,['03_' fileTag '_Cepstral_Sequences.png']));

%% 10. Plot the average pitch and formant results
fig = figure('Name','Average cepstral results','Color','w');
axis off;

text(0.08,0.88,'EE5334 Assignment 1 - Objective 2','FontSize',15,'FontWeight','bold');
text(0.08,0.76,['Word: ' wordName '     Vowel: ' vowelName],'FontSize',12);

text(0.08,0.65,sprintf('%d consecutive frames, %.1f ms frame length, %.1f ms frame shift', ...
    numberOfFrames,frameDuration*1000,frameShift*1000),'FontSize',11);

text(0.08,0.48,sprintf('Average pitch: %.2f Hz',averagePitch),'FontSize',13);
text(0.08,0.36,sprintf('Average F1: %.2f Hz',averageFormants(1)),'FontSize',13);
text(0.08,0.25,sprintf('Average F2: %.2f Hz',averageFormants(2)),'FontSize',13);
text(0.08,0.14,sprintf('Average F3: %.2f Hz',averageFormants(3)),'FontSize',13);

title('Average values from cepstral analysis');

saveFigure(fig,fullfile(outputFolder,['04_' fileTag '_Average_Results.png']));

fprintf('\nAll PNG plots have been saved in: %s\n',outputFolder);

%% =========================== LOCAL FUNCTIONS ===========================

function f = findBandPeak(frequency,envelopeDB,lowerFrequency,upperFrequency)
% Return the strongest local envelope peak inside the specified frequency band.

band = frequency>=lowerFrequency & frequency<=upperFrequency; % Select FFT bins in the required formant band
bandFrequency = frequency(band);             % Frequencies inside the selected band
bandEnvelope = envelopeDB(band);              % Smoothed spectral values inside the selected band

[peakValues,peakLocations] = findpeaks(bandEnvelope,bandFrequency); % Locate local maxima in the band

if isempty(peakValues)
    [~,index] = max(bandEnvelope);            % Use the largest envelope bin when no local peak is present
    f = bandFrequency(index);
else
    [~,index] = max(peakValues);               % Select the strongest local peak
    f = peakLocations(index);                  % Return its frequency in Hz
end

end

function [f1Band,f2Band,f3Band] = formantBands(vowelName)
% Broad formant frequency regions used for the selected Telugu vowel.

switch vowelName
    case {'/a/','/aa/','/au/'}
        f1Band = [300 1200]; f2Band = [800 2800]; f3Band = [1800 4200];

    case {'/i/','/ii/'}
        f1Band = [200 800]; f2Band = [1400 3500]; f3Band = [2300 4300];

    case {'/u/','/uu/'}
        f1Band = [200 900]; f2Band = [500 2000]; f3Band = [1700 3800];

    case {'/e/','/ee/','/ai/'}
        f1Band = [200 1000]; f2Band = [1000 3300]; f3Band = [2200 4300];

    case {'/o/','/oo/'}
        f1Band = [200 1000]; f2Band = [500 2000]; f3Band = [1700 3900];

    otherwise
        f1Band = [200 1200]; f2Band = [700 3300]; f3Band = [1800 4300];
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