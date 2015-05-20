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
    public static float initialAngle;
    public static float pixelsPerCentimeter;
    public static boolean buildMap = true;

    public static void main(String[] args) {
        Settings.init();
        try {
            matlabProxy = matlabProxyFactory.getProxy();
        } catch (MatlabConnectionException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        if(!Settings.ROBOT_TESTING_MODE) {
            getImage(Settings.IMAGE_NAME);
            determinePath(Settings.IMAGE_NAME);
            transformPath();
            followPath();
        } else {
            testingMethod();
        }
        try {
            matlabProxy.exit();
        } catch (MatlabInvocationException e) {
            e.printStackTrace();
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
            initialAngle = Float.parseFloat(data[1].substring(data[1].indexOf('=')+1));
            while(initialAngle >= 360) {
                initialAngle = initialAngle - 360;
            }
        }
    }

    /** Transform the path of image coordinates to a sequence of distances and angles */
    private static void transformPath() {
        System.out.println("Transforming path into directions");
        directions = new float[path.length-1][2];
        float prevAngle = initialAngle;
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
            while(it<Settings.MAX_ITERATIONS) {
                float[][] list = directions;
                if(hasFinished()) {
                    System.out.print("Robot has reached destination after "+it+" iterations");
                    return;
                }
                for (float[] instructions : list) {
                    float angle = instructions[0];      //angle in degrees
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
                        if (Settings.ACTIVE_ANGLE_CONTROL) {
                            controlAngle(angle, it);
                        } else {
                            robotHelper.rotate(angle);
                        }
                        if (distance > Settings.MAX_DRIVING_DISTANCE) {
                            robotHelper.driveForward(Settings.MAX_DRIVING_DISTANCE);
                            break;
                        } else {
                            robotHelper.driveForward(distance);
                            if (Settings.RECALCULATE_PATH_EVERY_ITERATION) {
                                break;
                            }
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
        double dist = Math.sqrt((startX - endX) * (startX - endX) + (startY - endY) * (startY - endY));
        return dist<=Settings.ENDING_MARGIN;
    }

    private static void controlAngle(float angleToRotate, int iteration) {
        int it = 0;
        System.out.println("Entering active angle control");
        String name = "angle"+iteration+"-"+it+".jpg";
        getImage(name);
        float currentAngle = (float) getCurrentAngle(name);
        float setPoint = currentAngle + angleToRotate;
        float toRotate = setPoint - currentAngle;
        if(toRotate>180) {
            toRotate = toRotate-360;
        } else if(toRotate<-180) {
            toRotate = toRotate+360;
        }
        while(Math.abs(toRotate)>=Settings.MAX_ANGLE_ERROR) {
            robotHelper.rotate(toRotate);
            it = it+1;
            name = "angle"+iteration+"-"+it+".jpg";
            getImage(name);
            currentAngle = (float) getCurrentAngle(name);
            toRotate = setPoint - currentAngle;
            if(toRotate>180) {
                toRotate = toRotate-360;
            } else if(toRotate<-180) {
                toRotate = toRotate+360;
            }
        }
    }

    private static double getCurrentAngle(String image) {
        Object[] returns = null;
        try {
            returns = matlabProxy.returningEval("getAngle('"+image+"')",1);
        } catch (MatlabInvocationException e) {
            e.printStackTrace();
        }
        if(returns !=null) {
            double[] angle = (double[]) returns[0];
            if (angle[0] > 180) {
                angle[0] = angle[0] - 360;
            } else if (angle[0] < -180) {
                angle[0] = angle[0] + 360;
            }
            return angle[0];
        } else {
            System.out.println("INTERNAL MATLAB ERROR WHILE DETERMINING ANGLE");
            System.exit(-1);
        }
        return 0;
    }

    private static void testingMethod() {
        TelnetHandler client = new TelnetHandler(Settings.ROBOT_IP, Settings.ROBOT_PORT);
        robotHelper = new RobotHelper(client);
        robotHelper.openConnection();
        for(int i=10;i<180;i=i+10) {
            robotHelper.rotate(i);
        }
        robotHelper.closeConnection();
    }
}
