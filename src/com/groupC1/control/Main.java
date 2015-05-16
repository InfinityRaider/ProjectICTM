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

    /** RobotHelper to control the robot */
    private static RobotHelper robotHelper;

    /** The path to be sent to the robot (nx2) */
    public static int[][] path;
    public static float[][] directions;
    public static float startingAngle;
    public static float pixelsPerCentimeter;

    public static void main(String[] args) {
        Settings.init();
        getImage();
        determinePath();
        transformPath();
        followPath();
    }

    /** Comunicates with the camera to get a bird's eye image of the situation */
    private static void getImage() {
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
            IOHelper.writeImageJPG(Settings.WORKSPACE_DIRECTORY + "\\" + Settings.IMAGE_NAME, image);
        } catch (MalformedURLException e) {
            e.printStackTrace();
            System.exit(-1);
        }
    }

    /** Uses the Matlab proxy to run the matlab script to get a path from the image */
    private static void determinePath() {
        MatlabProxy proxy = null;
        try {
            proxy = matlabProxyFactory.getProxy();
        } catch (MatlabConnectionException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        //execute Matlab script
        if(proxy != null) {
            //if the proxy is not connected to a matlab session, there is no point in continuing.
            if(!proxy.isConnected()) {
                System.out.println("Proxy is not connected to Matlab");
                System.exit(-1);
            }
            try {
                proxy.eval("cd('"+Settings.WORKSPACE_DIRECTORY+"')");
                proxy.eval(Settings.MATLAB_COMMAND+"('"+Settings.IMAGE_NAME+"','"+Settings.PATH_NAME+"')");
                proxy.exit();
            } catch (MatlabInvocationException e) {
                e.printStackTrace();
                System.exit(-1);
            }
            //read path
            String[] csvData = IOHelper.readFile(Settings.WORKSPACE_DIRECTORY + '\\' + Settings.PATH_NAME, Settings.MAX_TRIES_UNTIL_TIMEOUT);
            path = IOHelper.parseData(csvData);
            String[] data = IOHelper.readFile(Settings.WORKSPACE_DIRECTORY + '\\' + Settings.FILE_NAME, Settings.MAX_TRIES_UNTIL_TIMEOUT);
            pixelsPerCentimeter = Float.parseFloat(data[0].substring(data[0].indexOf('=')+1));
            startingAngle = Float.parseFloat(data[1].substring(data[1].indexOf('=')+1));
        }
    }

    /** Transform the path of image coordinates to a sequence of distances and angles */
    private static void transformPath() {
        directions = new float[path.length-1][2];
        for(int i=1;i<path.length;i++) {
            int x0 = path[i-1][0];
            int y0 = path[i-1][1];
            int x1 = path[i][0];
            int y1 = path[i][1];
            directions[i-1][0] = (float) (Math.atan2(y1 - y0, x1 - x0)*180/Math.PI);
            directions[i-1][1] = ((float) Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)))/(100*pixelsPerCentimeter);
            if(i==1) {
                directions[0][0] = directions[0][0]-startingAngle;
            }
        }
    }

    /** Sends the necessary commands to the robot to follow the path */
    private static void followPath() {
        if(Settings.USE_TERATERM) {
            //Open TeraTerm
            CommandHelper.executeCommand(Settings.TERATERM_PATH);
        } else {
            robotHelper = new RobotHelper(new TelnetHandler(Settings.ROBOT_IP, Settings.ROBOT_PORT));
            robotHelper.openConnection();
            for (float[] instructions : directions) {
                float angle = instructions[0];      //angle in degrees
                float distance = instructions[1];   //distance in meters
                robotHelper.rotate(angle);
                robotHelper.driveForward(distance);
            }
            robotHelper.closeConnection();
        }
    }
}
