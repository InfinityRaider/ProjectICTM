package com.groupC1.control.reference;

import com.groupC1.control.util.DebugHelper;
import com.groupC1.control.util.IOHelper;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;

public class Settings {
    public static Integer MAX_TRIES_UNTIL_TIMEOUT = Reference.DEFAULT_TRIES;
    public static Integer SLEEP_TIME = Reference.DEFAULT_SLEEP_TIME;
    public static String WORKSPACE_DIRECTORY = System.getProperty("user.dir")+"\\matlab";
    public static String TERATERM_PATH =  System.getProperty("user.dir")+"\\teraterm\\SRV\\Teraterm\\ttermpro.exe";
    public static Boolean DEBUG_MODE = false;
    public static String IMAGE_NAME = Reference.IMAGE_FILE_NAME;
    public static String PATH_NAME = Reference.PATH_FILE_NAME;
    public static String MATLAB_COMMAND = Reference.COMMAND;
    public static String ROBOT_IP = Reference.IP_SUBNET+Reference.ROBOT_SUBNET_MASK;
    public static Integer ROBOT_PORT = Integer.parseInt(Reference.ROBOT_PORT);
    public static String CAMERA_URL = "http://"+Reference.IP_SUBNET+Reference.CAMERA_SUBNET_MASK+Reference.CAMERA_URL;
    public static String CAMERA_USERNAME = Reference.CAMERA_USER;
    public static String CAMERA_PASSWORD = Reference.CAMERA_PASSWORD;
    public static Long TIMEOUT_WAIT_TIME = (long) 5000;
    public static Boolean USE_TERATERM = false;
    public static String FILE_NAME = "scaling_and_orient.txt";
    public static Boolean EXECUTE_MATLAB = true;
    public static Integer DRIVE_TIME_BEFORE_CORRECTION = 2000;
    //public static Character START_DATA_CHAR = Reference.START_DATA_CHAR;
    //public static Character STOP_DATA_CHAR = Refrence.STOP_DATA_CHAR;

    public static void init() {
        String defaultData = getDefaultSettings();
        String settings = IOHelper.readOrWriteSettings("Settings", defaultData);
        setSettings(IOHelper.getLinesArrayFromData(settings));
    }

    private static String getDefaultSettings() {
        Field[] settings = Settings.class.getDeclaredFields();
        String data = "";
        for(Field field:settings) {
            try {
                data = data + field.getName()+'='+field.get(null)+'\n';
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }
        return data;
    }

    private static void setSettings(String[] settings) {
        for(String setting:settings) {
            int index = setting.indexOf('=');
            if(index<0) {continue;}
            String name = setting.substring(0, index);
            String value = setting.substring(index + 1);
            DebugHelper.debug("Trying to set " + name + " to "+value+'\n');
            try {
                Field field = Settings.class.getField(name);
                DebugHelper.debug("Field: " + field.getName() + '\n');
                Class clazz = field.getType();
                DebugHelper.debug("Class: " + clazz.getName()+'\n');
                Constructor constructor = clazz.getConstructor(new Class[]{String.class});
                field.set(null, constructor.newInstance(value));
            } catch(Exception e) {
                e.printStackTrace();
                System.exit(-1);
            }
        }
    }
}
