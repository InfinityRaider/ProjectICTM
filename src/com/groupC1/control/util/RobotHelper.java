package com.groupC1.control.util;

import com.groupC1.control.network.TelnetHandler;
import com.groupC1.control.reference.Settings;

public class RobotHelper {
    private static final char RIGHT = '9';
    private static final char LEFT = '8';
    private static final char FORWARD = '5';
    private static final char STOP = '6';

    private TelnetHandler telnetHandler;
    private int totalTime;

    public RobotHelper(TelnetHandler telnetHandler) {
        this.telnetHandler = telnetHandler;
        totalTime = 0;
    }

    public void openConnection() {
        telnetHandler.connect();
        telnetHandler.sendMessage('%');
    }

    public void closeConnection() {telnetHandler.disconnect();}

    /** Makes the robot drive forward over the given distance */
    public void driveForward(float distance) {
        System.out.println("   driving "+distance+"m");
        if(distance == 0) {
            return;
        }
        float delay = driveDelay(distance);
        telnetHandler.sendMessage(FORWARD);
        try {
            Thread.sleep((int) delay);
            totalTime = totalTime + (int) delay;
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        telnetHandler.sendMessage(STOP);
    }

    public float driveDelay(float distance) {
        return 1000*(4.8F*distance+0.05F);
    }

    public boolean needsCorrection() {
        return this.totalTime >= Settings.DRIVE_TIME_BEFORE_CORRECTION;
    }

    public void corrected() {
        this.totalTime = 0;
    }

    /** Makes the robot rotate over the given angle */
    public void rotate(float angle) {
        angle = - angle;
        System.out.println("   Rotating "+angle+"°");
        if (angle == 0) {
            return;
        }
        float delay = rotationDelay(angle);
        telnetHandler.sendMessage(angle>0?LEFT:RIGHT);
        try {
            Thread.sleep((int) delay);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        telnetHandler.sendMessage(STOP);
    }

    public float rotationDelay(float angle) {
        return 1000*((angle>0?1:-1)*0.010F*angle+0.003F);
    }

    public void rotateLeftForTime(long time) {
        telnetHandler.sendMessage(LEFT);
        try {
            Thread.sleep(time);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        telnetHandler.sendMessage(STOP);
    }

    public void rotateRightForTime(long time) {
        telnetHandler.sendMessage(RIGHT);
        try {
            Thread.sleep(time);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        telnetHandler.sendMessage(STOP);
    }
}
