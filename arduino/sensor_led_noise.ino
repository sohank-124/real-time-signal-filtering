// Streams timestamped photoresistor data while injecting a controlled LED artifact
// Output format: "milliseconds,ADC"

const int sensorPin = A0;        // Photoresistor input

// LED used as a controlled optical noise source
const int ledPin = 6;            // Digital output driving LED
const int sampleRate = 50;       // Target sampling rate (Hz)
const int sampleInterval = 1000 / sampleRate;

// LED flicker parameters (10 Hz square wave)
const int blinkMs = 50;
unsigned long lastBlink = 0;
bool ledOn = false;

unsigned long lastSample = 0;

void setup() {
  Serial.begin(115200);          // Must match analysis-side baud rate
  pinMode(ledPin, OUTPUT);
  delay(800);                    // Allow serial connection to stabilize
}

void loop() {
  unsigned long t = millis();

  // Inject periodic optical artifact via LED flicker
  if (t - lastBlink >= (unsigned long)blinkMs) {
    ledOn = !ledOn;
    digitalWrite(ledPin, ledOn); // HIGH = ON for common-cathode LED
    lastBlink = t;
  }

  // Sample sensor and transmit timestamped value
  if (t - lastSample >= (unsigned long)sampleInterval) {
    int adc = analogRead(sensorPin);
    Serial.print(t);
    Serial.print(",");
    Serial.println(adc);
    lastSample = t;
  }
}
