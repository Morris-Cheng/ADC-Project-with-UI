#ifndef UART_CLASS_H
#define UART_CLASS_H

#include <QObject>
#include <windows.h>
#include <thread>
#include <atomic>
#include <string>

class FpgaComm : public QObject
{
    Q_OBJECT

    public:
        FpgaComm(const std::wstring& portName, DWORD baudRate = 115200, QObject *parent = nullptr);

        ~FpgaComm();

        bool start();
        void stop();
        //void send_value_to_FPGA(uint16_t input_value);

    signals:
        void rawValue(uint16_t raw_received_value); //function that receives values from FPGA output
        void voltageSend(double voltage); //function that sends the computed voltage to mainwindow

    private slots:
        void rawValueToVoltage(uint16_t raw_received_value); //function that receives raw values from FPGA and converts to voltage

    private:
        HANDLE hSerial;
        std::atomic<bool> run_flag;
        std::thread rxThread;
        DWORD baudRate;
        std::wstring portName;

        void listen_fpga(); // listens to input values from the FPGA
    };

#endif
