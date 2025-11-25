#include "uart_class.h"
#include <QDebug>
#include <iostream>

FpgaComm::FpgaComm(const std::wstring& portName, DWORD baudRate, QObject *parent)
    : QObject(parent),
    hSerial(INVALID_HANDLE_VALUE),
    run_flag(false),
    baudRate(baudRate),
    portName(portName)
{
    //Connect raw value signal to rawValueToVoltage slot
    connect(this, &FpgaComm::rawValue, this, &FpgaComm::rawValueToVoltage);
}

FpgaComm::~FpgaComm() {
    stop();
}

bool FpgaComm::start() {
    hSerial = CreateFile(portName.c_str(), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
    if (hSerial == INVALID_HANDLE_VALUE) {
        std::cerr << "無法開啟 " << std::string(portName.begin(), portName.end()) << std::endl;
        return false;
    }

    DCB dcb = { 0 };
    dcb.DCBlength = sizeof(dcb);
    if (!GetCommState(hSerial, &dcb)) return false;
    dcb.BaudRate = baudRate;
    dcb.ByteSize = 8;
    dcb.StopBits = ONESTOPBIT;
    dcb.Parity = NOPARITY;
    if (!SetCommState(hSerial, &dcb)) return false;

    COMMTIMEOUTS timeouts = { 0 };
    timeouts.ReadIntervalTimeout = 50;
    timeouts.ReadTotalTimeoutConstant = 50;
    timeouts.ReadTotalTimeoutMultiplier = 10;
    SetCommTimeouts(hSerial, &timeouts);

    run_flag = true;
    rxThread = std::thread(&FpgaComm::listen_fpga, this);

    return true;
}

void FpgaComm::stop() {
    if (run_flag) {
        run_flag = false;
        if (rxThread.joinable())
            rxThread.join();
    }
    if (hSerial != INVALID_HANDLE_VALUE) {
        CloseHandle(hSerial);
        hSerial = INVALID_HANDLE_VALUE;
    }
}

// void FpgaComm::send_value_to_FPGA(uint16_t input_value) {
//     std::cout << "Sending to FPGA: " << input_value << std::endl;

//     unsigned char pkt[2];
//     pkt[0] = input_value & 0xFF;        // Low byte
//     pkt[1] = (input_value >> 8) & 0xFF; // High byte

//     DWORD w;
//     WriteFile(hSerial, &pkt, 2, &w, NULL);
// }

void FpgaComm::listen_fpga() {
    uint16_t last_val = 0xFFFF;
    unsigned char byte, lo, hi;
    DWORD bytesRead;
    bool start_flag = true;

    while (run_flag) {
        if (ReadFile(hSerial, &byte, 1, &bytesRead, NULL) && bytesRead == 1) {
            if (byte == 0xFF) {
                if (ReadFile(hSerial, &lo, 1, &bytesRead, NULL) && bytesRead == 1) {
                    if (ReadFile(hSerial, &hi, 1, &bytesRead, NULL) && bytesRead == 1) {
                        uint16_t swval = (hi << 8) | lo; // FPGA 高低位串接
                        if (swval != last_val) {
                            emit rawValue(swval); //sends the raw value received from the FPGA to be converted into voltage
                            last_val = swval;
                        }
                    }
                }
            }
        }
    }
}

void FpgaComm::rawValueToVoltage(uint16_t rawValue){
    double voltage = 0;

    voltage = (static_cast<double>(rawValue) / 65535.0) * 5.0;  //converts the raw binary value into voltage
    emit voltageSend(voltage); //sends voltage to mainwindow
}
