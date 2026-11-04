# Telugu Speech Analysis

## EE5334 – Assignment 1

**Student:** Ajay Karthik  
**Roll Number:** 230102030  
**Language:** Telugu

## 1. Introduction

This repository contains the speech recordings and MATLAB
programs used for the acoustic analysis of Telugu vowels
and consonants.

The work focuses on examining the characteristics of
speech sounds using time-domain and frequency-domain
signal processing techniques.

Two recordings were prepared: one containing Telugu
vowel examples and another containing consonant examples.

## 2. Recording Details

The recordings were prepared using the following settings:

| Parameter | Value |
|---|---|
| Language | Telugu |
| Sampling Frequency | 44,100 Hz |
| Bit Resolution | 16 bits/sample |
| Audio Channels | Mono |
| Vowel Recording | Approximately 22.39 seconds |
| Consonant Recording | Approximately 55.93 seconds |

## 3. Vowels Recorded

The vowel recording contains twelve Telugu word examples.

| No. | Word | Target Vowel |
|---|---|---|
| 1 | Amma | /a/ |
| 2 | Aavu | /aa/ |
| 3 | Illu | /i/ |
| 4 | Eega | /ii/ |
| 5 | Uduta | /u/ |
| 6 | Ooyala | /uu/ |
| 7 | Eluka | /e/ |
| 8 | Eenugu | /ee/ |
| 9 | Aidu | /ai/ |
| 10 | Onte | /o/ |
| 11 | Oda | /oo/ |
| 12 | Aushadham | /au/ |

The detailed acoustic analysis focuses on three selected
vowels:

- Amma (/a/)
- Illu (/i/)
- Uduta (/u/)

## 4. Consonants Recorded

The consonant recording contains 25 examples arranged
according to five traditional places of articulation
and five manner-related categories.

### 4.1 Velar

| Consonant | Classification |
|---|---|
| ka | Voiceless unaspirated |
| kha | Voiceless aspirated |
| ga | Voiced unaspirated |
| gha | Voiced aspirated |
| nga | Nasal |

### 4.2 Palatal Series

| Consonant | Classification |
|---|---|
| ca | Voiceless unaspirated |
| cha | Voiceless aspirated |
| ja | Voiced unaspirated |
| jha | Voiced aspirated |
| nya | Nasal |

### 4.3 Retroflex

| Consonant | Classification |
|---|---|
| Ta | Voiceless unaspirated |
| Tha | Voiceless aspirated |
| Da | Voiced unaspirated |
| Dha | Voiced aspirated |
| Na | Nasal |

### 4.4 Apico-Dental

| Consonant | Classification |
|---|---|
| ta | Voiceless unaspirated |
| tha | Voiceless aspirated |
| da | Voiced unaspirated |
| dha | Voiced aspirated |
| na | Nasal |

### 4.5 Labial

| Consonant | Classification |
|---|---|
| pa | Voiceless unaspirated |
| pha | Voiceless aspirated |
| ba | Voiced unaspirated |
| bha | Voiced aspirated |
| ma | Nasal |

## 5. Repository Contents

| File | Description |
|---|---|
| Telugu_Vowels.wav | Recorded Telugu vowel examples |
| Telugu_Consonants.wav | Recorded Telugu consonant examples |
| Task1.m | Narrowband, harmonic, AMDF and LPC-based vowel analysis |
| Task1_Consonant_Analysis.m | Individual consonant waveform and spectrogram analysis |
| Task2.m | Cepstral pitch and formant analysis |
| Task1_Report.tex | Report for Objective 1 |
| Task2_Report.tex | Report for Objective 2 |
| Results/ | Generated MATLAB figures |

## 6. Signal Processing Methods

### Objective 1

The following methods are used:

1. Narrowband spectrogram analysis to observe
   harmonic structure and estimate fundamental frequency.
2. Harmonic-spacing analysis for pitch estimation.
3. Average Magnitude Difference Function (AMDF)
   for independent pitch estimation.
4. Wideband spectrogram analysis to examine
   vocal-tract resonances.
5. Linear Predictive Coding (LPC) for estimating
   and marking F1, F2 and F3.
6. Waveform and spectrogram analysis of individual
   consonant tokens.

### Objective 2

Cepstral analysis is performed using:

1. Real cepstrum calculation.
2. Pitch estimation from cepstral peaks.
3. Cepstral liftering with K = 30.
4. Reconstruction of the smoothed spectral envelope.
5. Estimation of F1, F2 and F3.
6. Framewise analysis using eight consecutive frames.

## 7. Software Requirements

- MATLAB
- Signal Processing Toolbox

## 8. Running the Programs

Place the two WAV recordings and MATLAB scripts in
the same working directory.

Run the required script from MATLAB:

```matlab
Task1
