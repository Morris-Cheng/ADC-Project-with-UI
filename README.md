# ADC Project

This project implements an **Analog-to-Digital Converter (ADC) interface** on an FPGA and includes an oscilloscope-style UI for visualizing sampled data.

---

## 📁 Project Structure
top.xpr -- Vivado project file (open this to run the design)

top.v -- Top-level Verilog module to upload to FPGA

Wiring Image.png -- Wiring diagram for hardware connections

Oscilloscope_UI/ -- Qt-based oscilloscope interface

---

## 🚀 Getting Started

### 1. **Open the Vivado Project**
Open the Vivado project file:

top.xpr

This loads the project with all required sources.

### 2. **Synthesize and Upload the Design**
Within Vivado:

1. Synthesize the project  
2. Implement the design  
3. Generate the bitstream  
4. Program the FPGA using `top.v` as the top module  

---

## 🔌 Hardware Setup

Wiring is shown in the included diagram:

**Wiring Image.png**

The diagram includes:

- ADC → FPGA pin connections 

Ensure wiring matches the diagram before powering the system.

---

## 📊 Oscilloscope UI

The folder `Oscilloscope_UI/` contains a Qt-based graphical interface that:

- Displays real-time ADC samples  
- Plots the waveform  
- Communicates with the FPGA over UART  

### Running the UI

If using Qt Creator:

1. Open the `Oscilloscope_UI` project  
2. Build and run  
3. Select the correct serial/UART port  
4. Begin capturing and viewing data  

---

## 🛠 Requirements

### Hardware
- FPGA development board  
- External ADC module  
- USB-UART interface  

### Software
- Vivado  
- Qt (Qt Creator recommended)

---
