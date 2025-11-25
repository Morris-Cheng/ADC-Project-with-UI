#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QMessageBox>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtCharts/QValueAxis>
#include <QTimer>

static int sampleIndex = 0;

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    //Create FPGA object for receiving values
    FPGA_ADC = new FpgaComm(L"COM5");

    if(!FPGA_ADC->start()){
        QMessageBox::critical(this, "Error", "Failed to open COM port");
    }

    //connect voltage output from uart to mainwindow
    connect(FPGA_ADC, &FpgaComm::voltageSend, this, &MainWindow::voltageReceive);

    //create series to store voltage values
    QLineSeries *voltageArray = new QLineSeries();

    //create QChart
    QChart *chart = new QChart();

    //set the name for the series, only visible if the legend was enabled
    voltageArray -> setName("Voltage");

    //add the series into the chart
    chart -> addSeries(voltageArray);

    //setting up the pen used to plot the data
    QPen penVoltage(Qt::blue);
    penVoltage.setWidth(2);
    voltageArray -> setPen(penVoltage);

    //Axis
    QValueAxis *axisX = new QValueAxis;
    QValueAxis *axisY = new QValueAxis;

    axisX -> setRange(0, 1000); //only show the last 1000 samples
    axisY -> setRange(0, 5);    //0 to 5V

    axisX -> setTitleText("");
    axisY -> setTitleText("Voltage (V)");

    chart -> setAxisX(axisX, voltageArray);
    chart -> setAxisY(axisY, voltageArray);

    //sending the values to the chart
    ui -> voltagePlot -> setChart(chart);

    // === Timer to continuously update the chart ===
    QTimer* updateTimer = new QTimer(this);
    connect(updateTimer, &QTimer::timeout, this, [=]() {
        voltageArray->append(sampleIndex, voltageReceived);

        // Keep only last 100 points visible
        if (sampleIndex > 1000) {
            axisX->setRange(sampleIndex - 1000, sampleIndex);
        }

        sampleIndex++;
    });
    updateTimer->start(20); // update every 50 ms (20 Hz)
}

MainWindow::~MainWindow()
{
    FPGA_ADC->stop();
    delete FPGA_ADC;
    delete ui;
}

//connects voltage from uart to mainwindow
void MainWindow::voltageReceive(double voltage){
    voltageReceived = voltage;

    //print the voltage output number to the line edit
    ui -> voltageOutput -> setText(QString::number(voltage) + "V");
}
