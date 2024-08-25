% Author: Augustin H. Standke (s233067@dtu.dk / standkeaugustin@gmail.com)
% Course: 31245 Acoustic Conditions at the Roskilde Festival F24
% -------------------------------------------------------------------------
% Important!!! excitation signal and response recording need to have same
% fs and be mono not stereo

clc
clear
close all

signal.type = "arbitrary"; % choices are "mls"; "sweep"; "arbitrary"
threshold_percentage = 0.2; % relic of automatic onset detection

% Open file dialog for excitation signal
[signal.filename, signal.pathname] = uigetfile('*.wav', 'Select a .wav excitation signal file');

% Load the .wav file
[signal.y, signal.Fs] = audioread(fullfile(signal.pathname, signal.filename));

% Open file dialog for system response signal
[response.filename, response.pathname] = uigetfile('*.wav', 'Select a .wav response file');

% Load the .wav file
[response.y, response.Fs] = audioread(fullfile(response.pathname, response.filename));

% Cutting at onset of IR
response.onset_sample = detect_onset(signal.y, response.y, response.Fs, threshold_percentage);
response.cut = (response.y(response.onset_sample:length(response.y)));


% Zero padding IR of excitation signal
padding = zeros(length(response.cut)-length(signal.y),1);
signal.padded = [signal.y; padding];

% Verification plot
figure
hold on
plot(signal.padded)
plot(response.cut)
title("Verification plot of onset and cutting")
xlabel("Samples")
ylabel("Amplitude")
hold off


% Generate the impulse response
switch signal.type
    case "mls"

        % Ensure both signals are column vectors
        mls_signal = signal.padded(:);
        response_signal = response.cut(:);
        
        % Create an impulse response using cross-correlation
        impulse_response = ifft(fft(response_signal)./fft(mls_signal));
        
        % Plot the impulse response
        figure
        plot(impulse_response);
        title('Impulse Response of MLS signal');
        xlabel('Samples');
        ylabel('Amplitude');


    case "sweep"

        % Ensure both signals are column vectors
        sweep_signal = signal.y(:);
        response_signal = response.cut(:);
        
        % Perform deconvolution using circular convolution
        N = length(sweep_signal);
        M = length(response_signal);
        
        % Zero-pad the shorter signal to match the length of the longer signal
        if N > M
            response_signal = [response_signal; zeros(N - M, 1)];
        else
            sweep_signal = [sweep_signal; zeros(M - N, 1)];
        end
        
        % Perform FFT on both signals
        FFT_sweep_signal = fft(sweep_signal);
        FFT_response_signal = fft(response_signal);
        
        % Deconvolution in the frequency domain
        Hinv = conj(FFT_sweep_signal) ./ (FFT_sweep_signal .* conj(FFT_sweep_signal) + eps);
        impulse_response = ifft(FFT_response_signal .* Hinv);

        % Plot the results
        t = (0:length(response_signal)-1) / signal.Fs; % Time vector
        
        figure;
        subplot(3,1,1);
        plot(sweep_signal);
        title('Sweep Signal');
        xlabel('Time (s)');
        ylabel('Amplitude');
        
        subplot(3,1,2);
        plot(t, response_signal);
        title('Response Signal');
        xlabel('Time (s)');
        ylabel('Amplitude');
        
        subplot(3,1,3);
        plot(t, impulse_response);
        title('Impulse Response');
        xlabel('Time (s)');
        ylabel('Amplitude');

    
    case "arbitrary"
        
        % Ensure both signals are column vectors
        arbitrary_signal = signal.y(:);
        response_signal = response.cut(:);
        
        N = length(arbitrary_signal);
        M = length(response_signal);
        
        % Zero-pad the shorter signal to match the length of the longer signal
        if N > M
            response_signal = [response_signal; zeros(N - M, 1)];
        else
            arbitrary_signal = [arbitrary_signal; zeros(M - N, 1)];
        end
        
        normalized_response = response_signal.*(max(abs(arbitrary_signal))/max(abs(response_signal)));
        
        % Perform FFT on both signals
        FFT_arbitrary_signal = fft(arbitrary_signal);
        FFT_response_signal = fft(normalized_response);

        % Deconvolution in the frequency domain
        Hinv = conj(FFT_arbitrary_signal) ./ (FFT_arbitrary_signal .* conj(FFT_arbitrary_signal) + eps);
        impulse_response = ifft(FFT_response_signal .* Hinv);
        
        
        % Plot the impulse response
        figure
        plot(impulse_response);
        title('Impulse Response of arbitrary signal');
        xlabel('Samples');
        ylabel('Amplitude');

    otherwise
        
        print("Nothing was selected! Check script header.")        
end

normalized_impulse_response = impulse_response.*(0.99/max(abs(impulse_response)));

% Saving the file
[filename, pathname] = uiputfile('*.wav', 'Save Impulse Response as');
audiowrite(fullfile(pathname, filename), normalized_impulse_response, signal.Fs);
