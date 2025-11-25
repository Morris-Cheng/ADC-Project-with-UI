#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "uart_class.h"

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

    public:
        MainWindow(QWidget *parent = nullptr);
        ~MainWindow();

    private slots:
        void voltageReceive(double voltage);

    private:
        Ui::MainWindow *ui;
        FpgaComm *FPGA_ADC;

        double voltageReceived;
};
#endif // MAINWINDOW_H
