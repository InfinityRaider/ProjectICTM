package com.groupC1.control.reference;

public abstract class Reference {
    public static final String PATH_FILE_NAME = "path.csv";
    public static final String IMAGE_FILE_NAME = "foto.jpg";
    public static final String WORKSPACE_DIRECTORY = "F:\\Unief\\1e Master\\ICT & Mechatronica\\Matlab";
    public static final String MATLAB_DIRECTORY = "C:\\Program Files\\MATLAB\\R2014b/bin/matlab.exe";
    public static final String COMMAND = "MainScript";

    public static final String IP_SUBNET = "169.254.0";

    public static final String ROBOT_SUBNET_MASK = ".10";
    public static final String ROBOT_PORT = "10001";

    public static final String CAMERA_SUBNET_MASK = ".30";
    public static final String CAMERA_URL = "/axis-cgi/jpg/image.cgi?resolution=cgi";
    public static final String CAMERA_USER = "root";
    public static final String CAMERA_PASSWORD = "admin";

    public static final int DEFAULT_TRIES = 200;
    public static final int DEFAULT_SLEEP_TIME = 10;

    public static final char START_DATA_CHAR = 'a';
    public static final char STOP_DATA_CHAR = 'b';

    public static final String[] COMMANDS = {

    };
/*
Download file from powershell:
PowerShell.exe
$client = new-object System.Net.WebClient
$client.DownloadFile("169.254.0.30/axis-cgi/jpg/image.cgi?resolution=cgi", "C:\temp\test.jpg")
 */

}
