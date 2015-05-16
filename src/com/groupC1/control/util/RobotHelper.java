package com.groupC1.control.util;

import com.groupC1.control.network.TelnetHandler;

public class RobotHelper {
    private static final char RIGHT = '9';
    private static final char LEFT = '8';
    private static final char FORWARD = '5';
    private static final char STOP = '6';

    private TelnetHandler telnetHandler;

    public RobotHelper(TelnetHandler telnetHandler) {
        this.telnetHandler = telnetHandler;
    }

    public void openConnection() {telnetHandler.connect();}

    public void closeConnection() {telnetHandler.disconnect();}

    /** Makes the robot drive forward over the given distance */
    public void driveForward(float distance) {
        if(distance==0) {
            return;
        }
        float delay = 1000*(4.8F*distance+0.05F);
        telnetHandler.sendMessage(FORWARD);
        try {
            Thread.sleep((int) delay);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        telnetHandler.sendMessage(STOP);
    }

    /** Makes the robot rotate over the given angle */
    public void rotate(float angle) {
        if (angle == 0) {
            return;
        }
        float delay = 1000*((angle>0?1:-1)*0.010F*angle+0.003F);
        telnetHandler.sendMessage(angle>0?LEFT:RIGHT);
        try {
            Thread.sleep((int) delay);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        telnetHandler.sendMessage(STOP);
    }
}
