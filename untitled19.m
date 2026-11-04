%% EE5334 Assignment 1 - Telugu consonant analysis
% This program analyses the recorded Telugu consonant examples.
% The 25 consonants are arranged according to place of articulation
% and manner of articulation as given in the assignment.
% Individual waveforms and short-time spectrograms are generated
% to examine the acoustic characteristics of each consonant.

clc;
clear;
close all;

%% 1. Analysis settings

consonantFile = 'Telugu_Consonants.wav'; % Recorded Telugu consonant samples
outputFolder = 'Task1_Consonant_Results';    % Folder containing the PNG plots

frameDuration = 0.005;                       % Short analysis frame (5 ms)
frameShift = 0.001;                          % Frame shift (1 ms)
nfft = 4096;                                 % FFT length for the spectrogram
maxFrequency = 12000;                       % Highest displayed frequency

%% 2. Consonant classification

% The consonants are arranged row-wise according to the assignment chart.
consonant = { ...
    'ka','kha','ga','gha','nga', ...
    'ca','cha','ja','jha','nya', ...
    'Ta','Tha','Da','Dha','Na', ...
    'ta','tha','da','dha','na', ...
    'pa','pha','ba','bha','ma'};

% Place of articulation for each recorded consonant.
place = { ...
    'Velar','Velar','Velar','Velar','Velar', ...
    'Palatal','Palatal','Palatal','Palatal','Palatal', ...
    'Retroflex','Retroflex','Retroflex','Retroflex','Retroflex', ...
    'Apico-dental','Apico-dental','Apico-dental','Apico-dental','Apico-dental', ...
    'Labial','Labial','Labial','Labial','Labial'};

% Manner and voicing classification of the five consonant columns.
manner = { ...
    'Voiceless unaspirated','Voiceless aspirated','Voiced unaspirated','Voiced aspirated','Nasal', ...
    'Voiceless unaspirated','Voiceless aspirated','Voiced unaspirated','Voiced aspirated','Nasal', ...
    'Voiceless unaspirated','Voiceless aspirated','Voiced unaspirated','Voiced aspirated','Nasal', ...
    'Voiceless unaspirated','Voiceless aspirated','Voiced unaspirated','Voiced aspirated','Nasal', ...
    'Voiceless unaspirated','Voiceless aspirated','Voiced unaspirated','Voiced aspirated','Nasal'};

numberOfTokens = numel(consonant);

%% 3. Recorded consonant boundaries

% Start and end times were identified from the energy regions of
% the supplied recording. A short margin is retained around each
% active region to include the consonant and its vowel transition.

startTimes = [ ...
    2.55, 4.16, 6.00, 8.02, 9.75, ...
    12.28, 14.48, 16.41, 18.67, 20.90, ...
    23.70, 25.73, 27.76, 30.25, 32.24, ...
    34.25, 36.32, 38.35, 40.96, 43.26, ...
    45.58, 47.71, 49.61, 51.68, 53.74];

endTimes = [ ...
    3.20, 4.99, 6.71, 8.87, 10.60, ...
    12.97, 15.24, 17.23, 19.63, 21.88, ...
    24.51, 26.53, 28.63, 31.21, 33.16, ...
    34.92, 37.03, 39.32, 41.78, 44.10, ...
    46.43, 48.49, 50.43, 52.55, 54.73];

%% 4. Create the result folder

if ~isfolder(outputFolder)
    mkdir(outputFolder);                   % Create the folder for the consonant plots
end

%% 5. Read the consonant recording

[x,Fs] = audioread(consonantFile);         % Read the waveform and sampling frequency

if size(x,2)>1
    x = mean(x,2);                         % Convert stereo speech to mono
end

x = x(:);                                  % Keep the signal as a column vector

duration = numel(x)/Fs;                    % Total recording duration in seconds
time = (0:numel(x)-1)/Fs;                 % Time axis of the complete recording

%% 6. Plot the complete recording waveform

fig = figure('Name','Telugu consonant recording','Color','w');

plot(time,x,'k','LineWidth',0.7);
hold on;

% Mark the beginning and end of every selected consonant.
for k = 1:numberOfTokens

    xline(startTimes(k),'r--','LineWidth',0.7,'HandleVisibility','off');
    xline(endTimes(k),'b--','LineWidth',0.7,'HandleVisibility','off');

    text((startTimes(k)+endTimes(k))/2, ...
        max(x)*0.85,consonant{k}, ...
        'HorizontalAlignment','center', ...
        'FontSize',8);

end

xlabel('Time (s)');
ylabel('Amplitude');
title('Telugu consonant recording with selected token intervals');
xlim([0 duration]);
grid on;

exportgraphics(fig, ...
    fullfile(outputFolder,'00_Consonant_Recording_Waveform.png'), ...
    'Resolution',200);

close(fig);

%% 7. Spectrogram of the complete recording

windowLength = round(frameDuration*Fs);    % Frame length in samples
hopLength = round(frameShift*Fs);          % Frame advance in samples
window = hamming(windowLength,'periodic'); % Hamming window for the analysis

[Z,F,T] = spectrogram(x,window, ...
    windowLength-hopLength,nfft,Fs);       % Calculate the complete-recording spectrogram

specDB = 20*log10(abs(Z)+eps);             % Convert magnitude into decibels
specDB = specDB-max(specDB(:));            % Normalize the strongest component to 0 dB

fig = figure('Name','Consonant recording spectrogram','Color','w');

imagesc(T,F,specDB);
axis xy;
ylim([0 maxFrequency]);
caxis([-60 0]);
colormap(gca,'jet');
colorbar;

xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Wideband overview of the Telugu consonant recording');

% Mark the five articulation groups.
hold on;

for k = 1:5
    groupFirst = startTimes((k-1)*5+1);
    groupLast = endTimes(k*5);

    xline(groupFirst,'w--','LineWidth',0.9,'HandleVisibility','off');
    xline(groupLast,'w--','LineWidth',0.9,'HandleVisibility','off');
end

exportgraphics(fig, ...
    fullfile(outputFolder,'01_Consonant_Recording_Spectrogram.png'), ...
    'Resolution',200);

close(fig);

%% 8. Analyse each consonant separately

for k = 1:numberOfTokens

    % Convert the selected time boundaries into sample indices.
    firstSample = floor(startTimes(k)*Fs)+1;
    lastSample = floor(endTimes(k)*Fs)+1;

    tokenSignal = x(firstSample:lastSample); % Extract the current consonant
    tokenTime = startTimes(k)+(0:numel(tokenSignal)-1)/Fs;

    % Calculate the spectrogram of the individual consonant.
    [Z,F,T] = spectrogram(tokenSignal,window, ...
        windowLength-hopLength,nfft,Fs);

    tokenDB = 20*log10(abs(Z)+eps);        % Convert the token magnitude to decibels
    tokenDB = tokenDB-max(tokenDB(:));    % Normalize each token's strongest component

    %% 8A. Plot the waveform and spectrogram

    fig = figure('Name',['Consonant ' consonant{k}],'Color','w');

    tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

    % Time-domain waveform of the consonant.
    nexttile;

    plot(tokenTime,tokenSignal,'k','LineWidth',0.9);

    xlabel('Time (s)');
    ylabel('Amplitude');

    title(['Waveform - ' consonant{k}]);
    grid on;

    % Frequency components of the consonant over time.
    nexttile;

    imagesc(startTimes(k)+T,F,tokenDB);
    axis xy;

    ylim([0 maxFrequency]);
    caxis([-55 0]);
    colormap(gca,'jet');
    colorbar;

    xlabel('Time (s)');
    ylabel('Frequency (Hz)');

    title('Short-time spectrogram');

    sgtitle(sprintf('%s | %s | %s', ...
        consonant{k},place{k},manner{k}));

    %% 8B. Save the individual PNG plot

    placeTag = strrep(place{k},'-','_');
    mannerTag = strrep(manner{k},' ','_');

    plotName = sprintf('%02d_%s_%s_%s.png', ...
        k,consonant{k},placeTag,mannerTag);

    exportgraphics(fig, ...
        fullfile(outputFolder,plotName),'Resolution',200);

    close(fig);

end

%% 9. Combined consonant classification plot

fig = figure('Name','Telugu consonant classification','Color','w');

classificationText = {
    'VELAR'
    'ka       kha       ga       gha       nga'
    'Voiceless unaspirated | Voiceless aspirated | Voiced unaspirated | Voiced aspirated | Nasal'
    ' '
    'PALATAL'
    'ca       cha       ja       jha       nya'
    'Voiceless unaspirated | Voiceless aspirated | Voiced unaspirated | Voiced aspirated | Nasal'
    ' '
    'RETROFLEX'
    'Ta       Tha       Da       Dha       Na'
    'Voiceless unaspirated | Voiceless aspirated | Voiced unaspirated | Voiced aspirated | Nasal'
    ' '
    'APICO-DENTAL'
    'ta       tha       da       dha       na'
    'Voiceless unaspirated | Voiceless aspirated | Voiced unaspirated | Voiced aspirated | Nasal'
    ' '
    'LABIAL'
    'pa       pha       ba       bha       ma'
    'Voiceless unaspirated | Voiceless aspirated | Voiced unaspirated | Voiced aspirated | Nasal'
    };

axis off;

text(0.05,0.95,'Telugu consonants arranged by place and manner', ...
    'FontSize',14,'FontWeight','bold');

for k = 1:numel(classificationText)

    text(0.06,0.88-(k-1)*0.038,classificationText{k}, ...
        'FontSize',9,'FontName','Courier New');

end

exportgraphics(fig, ...
    fullfile(outputFolder,'27_Telugu_Consonant_Classification.png'), ...
    'Resolution',200);

close(fig);

%% 10. Print the consonant segmentation table

fprintf('\nTelugu consonant analysis\n\n');

fprintf('%-5s %-8s %-16s %-24s %-10s %-10s\n', ...
    'No.','Sound','Place','Manner','Start(s)','End(s)');

for k = 1:numberOfTokens

    fprintf('%-5d %-8s %-16s %-24s %-10.2f %-10.2f\n', ...
        k,consonant{k},place{k},manner{k}, ...
        startTimes(k),endTimes(k));

end

fprintf('\nAll consonant plots saved in: %s\n',outputFolder);