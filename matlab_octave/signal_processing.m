% Real-time sensor data acquisition and signal processing pipeline
% Reads timestamped Arduino data ("ms,adc"), applies filtering,
% and performs frequency-domain analysis (FFT and PSD)

pkg load signal
pkg load instrument-control

% ---------------- Configuration ----------------
PORT = 'COM3';          % Arduino serial port
BAUD = 115200;          % Must match Serial.begin() on Arduino
Tsec = 30;              % Data collection duration (seconds)
fc   = 5;               % Low-pass filter cutoff frequency (Hz)
% ------------------------------------------------

% Open serial connection to Arduino
arduino = serial(PORT, BAUD);
fopen(arduino);
pause(2);               % Allow Arduino to reset

% Flush any startup bytes from the serial buffer
try
  n = srl_available(arduino);
  if n > 0, srl_read(arduino, n); end
end

% Initialize storage and buffer
data = [];
buf  = '';
t0   = time();

fprintf('Collecting %d seconds of data...\n', Tsec);

% ---------------- Data Acquisition ----------------
while (time() - t0) < Tsec
  try
    n = srl_available(arduino);
  catch
    n = 64;             % Fallback read size
  end

  if n > 0
    [bytes, c] = srl_read(arduino, n);
    if c > 0
      buf = [buf, char(bytes)];

      % Process complete newline-terminated samples
      while true
        k = find(buf == "\n", 1);
        if isempty(k), break; end

        line = strtrim(buf(1:k-1));
        buf  = buf(k+1:end);

        % Parse "milliseconds,ADC"
        v = sscanf(line, '%f,%f');
        if numel(v) == 2
          data(end+1, :) = v.';
        end
      end
    end
  end
  pause(0.001);
end

fclose(arduino);

fprintf('Collected %d samples\n', rows(data));
if rows(data) == 0
  error('No samples collected. Close Serial Monitor and check port/baud.');
end

% ---------------- Time & Sampling Rate ----------------
t = data(:,1) / 1000;   % Convert ms to seconds
x = data(:,2);          % ADC values

% Estimate effective sampling frequency from timestamps
dt = diff(t);
dt = dt(dt > 0);
if isempty(dt)
  fs = 50;              % Fallback value
else
  fs = 1 / median(dt);
end

fprintf('Estimated sampling rate: %.2f Hz\n', fs);

% ---------------- Low-Pass Filtering ----------------
nyq = fs / 2;
if fc >= nyq
  fc = max(0.1, 0.4 * nyq);
end

[b, a] = butter(4, fc / nyq, 'low');
xf = filtfilt(b, a, x);

% ---------------- Frequency Analysis ----------------
% Remove DC offset prior to FFT
x0  = x  - mean(x);
xf0 = xf - mean(xf);

N     = length(x0);
halfN = floor(N/2);
f     = (0:N-1) * (fs / N);

X  = abs(fft(x0));
Xf = abs(fft(xf0));

% ---------------- Power Spectral Density ----------------
[pxx, fpsd] = pwelch(x0, [], [], [], fs);

% ---------------- Signal-to-Noise Ratio ----------------
sigP = var(xf);
noiP = var(x - xf);
SNRdB = (noiP <= 0) * Inf + (noiP > 0) * (10 * log10(sigP / noiP));

fprintf('Estimated SNR: %.2f dB\n', SNRdB);

% ---------------- Visualization ----------------
figure(1); clf;

subplot(4,1,1);
plot(t, x); grid on;
title('Raw Signal');
xlabel('Time (s)'); ylabel('ADC');
legend('Raw');

subplot(4,1,2);
plot(t, xf); grid on;
title(sprintf('Low-pass Filtered (%.2f Hz)', fc));
xlabel('Time (s)'); ylabel('ADC');
legend('Filtered');

subplot(4,1,3);
plot(f(1:halfN), X(1:halfN), 'r', 'linewidth', 1.2); hold on;
plot(f(1:halfN), Xf(1:halfN), 'b', 'linewidth', 1.2);
grid on; hold off;
title('FFT (DC Removed)');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
legend('Raw','Filtered');
xlim([0, min(25, fs/2)]);

subplot(4,1,4);
plot(fpsd, 10*log10(pxx), 'linewidth', 1.2); grid on;
title('Power Spectral Density (Welch)');
xlabel('Frequency (Hz)'); ylabel('dB/Hz');
legend('Raw PSD');
xlim([0, min(25, fs/2)]);

fprintf('Analysis complete.\n');

