package com.groupC1.control;

import com.groupC1.control.network.TelnetHandler;
import com.groupC1.control.reference.Settings;
import com.groupC1.control.util.CommandHelper;
import com.groupC1.control.util.IOHelper;
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

    /** TelnetHandler to communicate with the robot */
    private static TelnetHandler telnetHandler;

    /** The path to be sent to the robot (nx2) */
    public static int[][] path;

    public static void main(String[] args) {
        Settings.init();
        getImage();
        determinePath();
        sendPathToRobot();
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
            String[] csvData = IOHelper.readCSV(Settings.WORKSPACE_DIRECTORY, Settings.MAX_TRIES_UNTIL_TIMEOUT);
            path = IOHelper.parseData(csvData);
        }
    }

    /** Performs some magic to send the path to the robot */
    private static void sendPathToRobot() {
        if(Settings.USE_TERATERM) {
            //Open TeraTerm
            CommandHelper.executeCommand(Settings.TERATERM_PATH);
        }
        else {
            //Create TelnetHandler
            telnetHandler = new TelnetHandler(Settings.ROBOT_IP, Settings.ROBOT_PORT);
            telnetHandler.connect();
            telnetHandler.sendMessage(Settings.START_DATA_CHAR);
            for (int[] couple : path) {
                telnetHandler.sendMessage(couple[0]);
                telnetHandler.sendMessage(couple[1]);
            }
            telnetHandler.sendMessage(Settings.STOP_DATA_CHAR);
            telnetHandler.disconnect();
        }
    }
}
