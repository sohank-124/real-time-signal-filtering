// Photoresistor + controlled LED artifact + serial output "ms,adc"
const int sensorPin = A0;

// RGB channel pin used for flicker artifact
const int ledPin = 6;            // e.g., RED channel on D6 (PWM-capable, but we use digital)
const int sampleRate = 50;       // realistic with Serial; Octave will estimate actual fs anyway
const int sampleInterval = 1000 / sampleRate;

// Flicker settings (artifact frequency)
const int blinkMs = 50;          // 50ms toggle -> 10 Hz square wave
unsigned long lastBlink = 0;
bool ledOn = false;

unsigned long lastSample = 0;

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  delay(800);                    // allow serial to settle
}

void loop() {
  unsigned long t = millis();

  // Controlled artifact: 10 Hz LED flicker (square wave)
  if (t - lastBlink >= (unsigned long)blinkMs) {
    ledOn = !ledOn;
    digitalWrite(ledPin, ledOn); // common cathode: HIGH = on
    lastBlink = t;
  }

  // Sample + transmit: "ms,adc\n"
  if (t - lastSample >= (unsigned long)sampleInterval) {
    int adc = analogRead(sensorPin);
    Serial.print(t);
    Serial.print(",");
    Serial.println(adc);
    lastSample = t;
  }
}
