package com.groupC1.control;

import com.groupC1.control.network.TelnetHandler;
import com.groupC1.control.reference.Settings;
import com.groupC1.control.util.CommandHelper;
import com.groupC1.control.util.IOHelper;
import com.groupC1.control.util.RobotHelper;
import matlabcontrol.*;

import java.awt.image.BufferedImage;
import java.net.*;

public class Main {
    /** The MatlabProxyFactory instance used to communicate with Matlab*/
    private static MatlabProxyFactory matlabProxyFactory = new MatlabProxyFactory(new MatlabProxyFactoryOptions.Builder()
            /*.setMatlabLocation(Reference.MATLAB_DIRECTORY)*/
            /*.setMatlabStartingDirectory(new File(Reference.WORKSPACE_DIRECTORY))*/
            .setHidden(true)
            .build());
    private static MatlabProxy matlabProxy;

    /** RobotHelper to control the robot */
    private static RobotHelper robotHelper;

    /** The path to be sent to the robot (nx2) */
    public static int[][] path;
    public static float[][] directions;
    public static float angle;
    public static float pixelsPerCentimeter;
    public static boolean buildMap = true;

    public static void main(String[] args) {
        if(true) {
            Settings.init();
            try {
                matlabProxy = matlabProxyFactory.getProxy();
            } catch (MatlabConnectionException e) {
                e.printStackTrace();
                System.exit(-1);
            }
            getImage(Settings.IMAGE_NAME);
            determinePath(Settings.IMAGE_NAME);
            transformPath();
            followPath();
            try {
                matlabProxy.exit();
            } catch (MatlabInvocationException e) {
                e.printStackTrace();
            }
        } else {
            testingMethod();
        }
    }

    /** Comunicates with the camera to get a bird's eye image of the situation */
    private static void getImage(String imageName) {
        System.out.println("Getting Image");
        try {
            //Set username and password for the authenticator
            Authenticator auth = new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(Settings.CAMERA_USERNAME, Settings.CAMERA_PASSWORD.toCharArray());
                }
            };
            Authenticator.setDefault(auth);
            //Get image from url
            URL url = new URL(Settings.CAMERA_URL);
            BufferedImage image = IOHelper.readImageFromURL(url);
            IOHelper.writeImageJPG(Settings.WORKSPACE_DIRECTORY + "\\" + imageName, image);
        } catch (MalformedURLException e) {
            e.printStackTrace();
            System.exit(-1);
        }
    }

    /** Uses the Matlab proxy to run the matlab script to get a path from the image */
    private static void determinePath(String imageName) {
        System.out.println("Calculating path and robot position");
        //execute Matlab script
        if(matlabProxy != null) {
            if(Settings.EXECUTE_MATLAB) {
                //if the proxy is not connected to a matlab session, there is no point in continuing.
                if (!matlabProxy.isConnected()) {
                    System.out.println("Proxy is not connected to Matlab");
                    System.exit(-1);
                }
                try {
                    matlabProxy.eval("cd('" + Settings.WORKSPACE_DIRECTORY + "')");
                    matlabProxy.eval(Settings.MATLAB_COMMAND + "('" +imageName + "','" + Settings.PATH_NAME + "',"+ buildMap + "," + Settings.DEBUG_MODE+")");
                    buildMap = false;
                    //proxy.exit();
                } catch (MatlabInvocationException e) {
                    e.printStackTrace();
                    System.exit(-1);
                }
            }
            //read path
            String[] csvData = IOHelper.readFile(Settings.WORKSPACE_DIRECTORY + '\\' + Settings.PATH_NAME, Settings.MAX_TRIES_UNTIL_TIMEOUT);
            path = IOHelper.parseData(csvData);
            String[] data = IOHelper.readFile(Settings.WORKSPACE_DIRECTORY + '\\' + Settings.FILE_NAME, Settings.MAX_TRIES_UNTIL_TIMEOUT);
            pixelsPerCentimeter = Float.parseFloat(data[0].substring(data[0].indexOf('=')+1));
            angle = Float.parseFloat(data[1].substring(data[1].indexOf('=')+1));
            while(angle >= 360) {
                angle = angle - 360;
            }
        }
    }

    /** Transform the path of image coordinates to a sequence of distances and angles */
    private static void transformPath() {
        System.out.println("Transforming path into directions");
        directions = new float[path.length-1][2];
        float prevAngle = angle;
        for(int i=1;i<path.length;i++) {
            int x0 = path[i-1][0];
            int y0 = path[i-1][1];
            int x1 = path[i][0];
            int y1 = path[i][1];
            directions[i-1][0] = (float) (Math.atan2(y1 - y0, x1 - x0)*180/Math.PI) - prevAngle;
            prevAngle = (float) (Math.atan2(y1 - y0, x1 - x0)*180/Math.PI);
            directions[i-1][1] = ((float) Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)))/(100*pixelsPerCentimeter);
        }
    }

    /** Sends the necessary commands to the robot to follow the path */
    private static void followPath() {
        System.out.println("Sending commands to robot");
        if(Settings.USE_TERATERM) {
            //Open TeraTerm
            CommandHelper.executeCommand(Settings.TERATERM_PATH);
        } else {
            TelnetHandler client = new TelnetHandler(Settings.ROBOT_IP, Settings.ROBOT_PORT);
            robotHelper = new RobotHelper(client);
            robotHelper.openConnection();
            int it = 0;
            while(it<5) {
                float[][] list = directions;
                if(hasFinished()) {
                    System.out.print("Robot has reached destination after "+it+" iterations");
                    return;
                }
                for (float[] instructions : list) {
                    float angle = instructions[0];      //angle in degrees
                    if (angle > 180) {
                        angle = angle - 360;
                    } else if (angle < -180) {
                        angle = angle + 360;
                    }
                    float distance = instructions[1];   //distance in meters
                    if (robotHelper.needsCorrection()) {
                        System.out.println("Recalculating path");
                        it++;
                        getImage("foto" + it + ".jpg");
                        determinePath("foto" + it + ".jpg");
                        transformPath();
                        robotHelper.corrected();
                        break;
                    } else {
                        robotHelper.rotate(angle);
                        if(distance>0.5) {
                            robotHelper.driveForward(distance/2);
                            break;
                        } else {
                            robotHelper.driveForward(distance);
                        }
                    }
                }
            }
            robotHelper.closeConnection();
        }
    }

    private static boolean hasFinished() {
        int startX = path[0][0];
        int startY = path[0][1];
        int endX = path[path.length-1][0];
        int endY = path[path.length-1][1];
        double dist = Math.sqrt((startX-endX)*(startX-endX) + (startY-endY)*(startY-endY));
        return dist<=10;
    }

    private static void testingMethod() {
        TelnetHandler client = new TelnetHandler(Settings.ROBOT_IP, Settings.ROBOT_PORT);
        robotHelper = new RobotHelper(client);
        robotHelper.openConnection();

        for(int i=300;i>10;i=i-10) {
            robotHelper.rotateLeftForTime(i);
        }
        /*
        MatlabProxy proxy = null;
        try {
            proxy = matlabProxyFactory.getProxy();
        } catch (MatlabConnectionException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        int it = 0;
        float currentAngle = (float) determineAngleFromImage(proxy, it);
        float startAngle = currentAngle;
        float angleToRotate = 10;
        float targetAngle = currentAngle + angleToRotate;
        float margin = 2;
        float multiplier = 1.0F;
        float delay = getDelay(angleToRotate);
        while(Math.abs(targetAngle-currentAngle)>margin) {
            robotHelper.rotateRightForTime((int) (multiplier * delay));
            currentAngle = (float) determineAngleFromImage(proxy, it);
            delay = getDelay(targetAngle-currentAngle);
            multiplier = multiplier + 0.1F;
            it++;
        }
        */
        robotHelper.closeConnection();
    }
}
