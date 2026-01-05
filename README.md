# Real-Time Signal Filtering and Frequency Analysis

## Overview
This project demonstrates how noisy sensor data can be collected, filtered, and analyzed using basic signal processing techniques. An Arduino reads light intensity from a photoresistor while a periodically blinking LED injects controlled noise into the signal. The data is streamed to Octave/MATLAB, where filtering and frequency analysis are used to separate the underlying signal from noise.

This setup models how real-world biological signals often contain both meaningful information and unwanted interference.

## What This Project Does
- Collects timestamped sensor data from an Arduino in real time
- Injects controlled periodic noise using an LED
- Applies a low-pass digital filter to remove high-frequency noise
- Uses FFT (Fast Fourier Transform) to identify frequency components
- Uses Power Spectral Density (PSD) to show how signal energy is distributed
- Compares raw vs filtered data to evaluate noise removal

## Hardware Setup
- Arduino Uno
- Photoresistor (light sensor)
- Green LED (used as a periodic noise source)
- Resistors
- Breadboard and jumper wires

The LED is placed near the photoresistor and blinks at a fixed frequency, causing periodic changes in the sensor reading.

The resulting graph, the TinkerCAD model and a demo video are included in the documentation folder.

## Software
### Arduino
- Reads the photoresistor
- Blinks the LED at a fixed frequency
- Sends data as timestamp,ADC_value over serial

### Octave / MATLAB
- Reads serial data
- Estimates the actual sampling rate from timestamps
- Applies a low-pass Butterworth filter
- Performs FFT and PSD analysis
- Visualizes raw and processed signals

## Results
The injected LED flicker appears as a clear peak in the frequency spectrum at the expected frequency. After filtering, these components are strongly reduced while the underlying signal remains intact. The FFT and PSD plots agree, confirming an effective noise removal.

## Repository Structure
arduino/
sensor_led_noise.ino

matlab_octave/
signal_processing.m

documentation/
octaveGraphs.png,
Octave_code_demonstration.mp4,
Arduino_TinkerCAD_Model.png

## Why This Matters
The filtering and frequency analysis techniques used here are the same tools applied in many real signal-processing tasks, including neuroscience and biomedical engineering. This project focuses on understanding how noise enters a system and how it can be analyzed and reduced.
