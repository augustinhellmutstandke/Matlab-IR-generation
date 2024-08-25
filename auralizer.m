% Auralizer in MATLAB with Resampling and Stereo Handling for Both IR and Anechoic Recording

% Load Impulse Response
[irFile, irPath] = uigetfile('*.wav', 'Select the Impulse Response File');
if isequal(irFile, 0)
    disp('User selected Cancel');
    return;
else
    irFilePath = fullfile(irPath, irFile);
    [impulseResponse, fsIR] = audioread(irFilePath);
    disp(['User selected ', irFilePath]);
end

% Load Anechoic Recording
[anFile, anPath] = uigetfile('*.wav', 'Select the Anechoic Recording File');
if isequal(anFile, 0)
    disp('User selected Cancel');
    return;
else
    anFilePath = fullfile(anPath, anFile);
    [anechoicRecording, fsAn] = audioread(anFilePath);
    disp(['User selected ', anFilePath]);
end

% Resample if sampling rates do not match
if fsIR ~= fsAn
    disp('Sampling rates do not match. Resampling...');
    if fsIR > fsAn
        anechoicRecording = resample(anechoicRecording, fsIR, fsAn);
        fsAn = fsIR;
    else
        impulseResponse = resample(impulseResponse, fsAn, fsIR);
        fsIR = fsAn;
    end
end

% Check if the anechoic recording is stereo
isAnechoicStereo = size(anechoicRecording, 2) == 2;
isImpulseStereo = size(impulseResponse, 2) == 2;

if isAnechoicStereo && isImpulseStereo
    disp('Both anechoic recording and impulse response are stereo. Applying corresponding channels...');
    % Convolve each channel separately
    auralizedOutputLeft = conv(anechoicRecording(:, 1), impulseResponse(:, 1));
    auralizedOutputRight = conv(anechoicRecording(:, 2), impulseResponse(:, 2));
    % Combine the two channels
    auralizedOutput = [auralizedOutputLeft, auralizedOutputRight];
elseif isAnechoicStereo
    disp('Anechoic recording is stereo and impulse response is mono. Applying impulse response to both channels...');
    % Convolve each channel separately with the mono impulse response
    auralizedOutputLeft = conv(anechoicRecording(:, 1), impulseResponse);
    auralizedOutputRight = conv(anechoicRecording(:, 2), impulseResponse);
    % Combine the two channels
    auralizedOutput = [auralizedOutputLeft, auralizedOutputRight];
elseif isImpulseStereo
    disp('Anechoic recording is mono and impulse response is stereo. Applying each impulse response channel to the mono recording...');
    % Convolve the mono anechoic recording with each channel of the stereo impulse response
    auralizedOutputLeft = conv(anechoicRecording, impulseResponse(:, 1));
    auralizedOutputRight = conv(anechoicRecording, impulseResponse(:, 2));
    % Combine the two channels
    auralizedOutput = [auralizedOutputLeft, auralizedOutputRight];
else
    disp('Both anechoic recording and impulse response are mono. Applying impulse response...');
    % Convolve the mono anechoic recording with the mono impulse response
    auralizedOutput = conv(anechoicRecording, impulseResponse);
end

% Normalize the output
auralizedOutput = auralizedOutput / max(abs(auralizedOutput(:)));


% Remove the .wav extension from anFile and irFile
anFile = erase(anFile, '.wav');
irFile = erase(irFile, '.wav');

% Save the auralized output
outputFile = fullfile(anPath, [anFile '_auralized_with_' irFile '.wav']);
audiowrite(outputFile, auralizedOutput, fsIR);
disp(['Auralized output saved to ', outputFile]);
