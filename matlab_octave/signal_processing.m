% This script implements a pipeline for data acquisition and analysis

pkg load signal
pkg load instrument-control

% Configuration and Serial Setup
PORT = 'COM3';          % Arduino serial port
BAUD = 115200;          % Baud rate
Tsec = 30;              % Data collection duration (seconds)
fc   = 5;               % Low-pass cutoff frequency (Hz)

% Open serial connection
arduino = serial(PORT, BAUD);
fopen(arduino);
pause(2);               % Allow Arduino reset

% Flush startup bytes
try
  n = srl_available(arduino);
  if n > 0, srl_read(arduino, n); end
end

% Initialize buffers
data = [];
buf  = '';
t0   = time();

fprintf('Collecting %d seconds of data...\n', Tsec);

% ---------------- Data Acquisition ----------------
while (time() - t0) < Tsec
  try
    n = srl_available(arduino);
  catch
    n = 64;
  end

  if n > 0
    [bytes, c] = srl_read(arduino, n);
    if c > 0
      buf = [buf, char(bytes)];

      while true
        k = find(buf == "\n", 1);
        if isempty(k), break; end

        line = strtrim(buf(1:k-1));
        buf  = buf(k+1:end);

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

% ---------------- Time and Signal ----------------
t = data(:,1) / 1000;   % ms -> seconds
x = data(:,2);

% --------  remove serial glitches / timestamp resets --------
good = [true; diff(t) > 0];   % keep strictly increasing timestamps
t = t(good);
x = x(good);

[t, ia] = unique(t, 'stable'); % remove duplicates
x = x(ia);
% ---------------------------------------------------------------

% Estimate sampling rate from cleaned timestamps
dt = diff(t);
if isempty(dt)
  fs = 50;
else
  fs = 1 / median(dt);
end

fprintf('Estimated sampling rate: %.2f Hz\n', fs);

% ---------------- Low-Pass Filter ----------------
nyq = fs / 2;
if fc >= nyq
  fc = max(0.1, 0.9 * nyq);
end

[b, a] = butter(4, fc / nyq, 'low');
xf = filtfilt(b, a, x);

% ---------------- FFT ----------------
x0  = x  - mean(x);
xf0 = xf - mean(xf);

N     = length(x0);
halfN = floor(N/2);
f     = (0:N-1) * (fs / N);

X  = abs(fft(x0));
Xf = abs(fft(xf0));

% ---------------- PSD ----------------
[pxx, fpsd] = pwelch(x0, [], [], [], fs);

% ---------------- SNR ----------------
sigP = var(xf);
noiP = var(x - xf);
SNRdB = (noiP <= 0) * Inf + (noiP > 0) * (10 * log10(sigP / noiP));
fprintf('Estimated SNR: %.2f dB\n', SNRdB);

% ---------------- Plots ----------------
figure(1); clf;

subplot(4,1,1);
plot(t, x, 'color', [0.7 0.7 0.7]); hold on;
plot(t, xf, 'b', 'linewidth', 1.2);
title('Time Domain: Raw Signal vs Filtered Signal');
xlabel('Time (s)'); ylabel('ADC');
legend('Raw Noise','Clean Signal');

subplot(4,1,2);
plot(t, xf); grid on;
title(sprintf('Filtered Signal Zoom (%.2f Hz Low-pass)', fc));
xlabel('Time (s)'); ylabel('ADC');

subplot(4,1,3);
plot(f(1:halfN), X(1:halfN), 'r', 'linewidth', 1.0); hold on;
plot(f(1:halfN), Xf(1:halfN), 'b', 'linewidth', 1.2);
grid on; hold off;
title('Frequency Spectrum (FFT - DC Removed)');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
legend('Raw FFT','Filtered FFT');
xlim([0, min(25, fs/2)]);

subplot(4,1,4);
plot(fpsd, 10*log10(pxx), 'linewidth', 1.2); grid on;
title('Power Spectral Density (Welch Estimator)');
xlabel('Frequency (Hz)'); ylabel('dB/Hz');
xlim([0, min(25, fs/2)]);

fprintf('Analysis complete.\n');

