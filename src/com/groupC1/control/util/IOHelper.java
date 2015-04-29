package com.groupC1.control.util;

import com.groupC1.control.reference.Settings;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.net.URL;
import java.util.ArrayList;

public class IOHelper {
    public static BufferedImage readImageFromURL(URL url) {
        BufferedImage image = null;
        try {
            image = ImageIO.read(url);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return image;
    }

    public static void writeImageJPG(String fileName, BufferedImage img) {
        File file = new File(fileName);
        try {
            ImageIO.write(img, "JPEG", file);
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(-1);
        }
    }

    public static String[] readCSV(String fileName, int tries) {
        ArrayList<String> lines = new ArrayList<String>();
        BufferedReader reader = null;
        //Wait for Matlab to finish its scripts, if Matlab takes too long, we assume it has failed
        File file = null;
        int counter = 0;
        while(file==null || !file.exists()) {
            try {
                Thread.sleep(Settings.SLEEP_TIME);
            } catch (InterruptedException e) {
                e.printStackTrace();
                System.exit(-1);
            }
            file = new File(fileName);
            counter++;
            if(counter==tries) {
                System.out.println("Maximum number of tries exceeded, ending");
                System.exit(-1);
            }
        }
        try {
            reader = new BufferedReader(new FileReader(file));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        StringBuilder builder = new StringBuilder();
        try {
            while (reader.readLine() != null) {
                lines.add(reader.readLine());
            }
        } catch (Exception e) {
            System.out.println("The codings, they do nothing");
            System.exit(-1);
        }
        try {
            reader.close();
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        return lines.toArray(new String[lines.size()]);
    }

    public static int[][] parseData(String[] input) {
        int[][] data = new int[input.length][2];
        for (int i = 0; i < input.length; i++) {
            String[] splitLine = input[i].split(",");
            if (splitLine.length == 2) {
                data[i][0] = Integer.parseInt(splitLine[0]);
                data[i][1] = Integer.parseInt(splitLine[1]);
            } else {
                System.out.println("ERROR: invalid data");
                System.exit(-1);
            }
        }
        return data;
    }

    public static String readOrWriteSettings(String fileName, String defaultData) {
        File file = new File(fileName+".txt");
        if(file.exists() && !file.isDirectory()) {
            try {
                FileInputStream inputStream = new FileInputStream(file);
                byte[] input = new byte[(int) file.length()];
                try {
                    inputStream.read(input);
                    inputStream.close();
                    return new String(input, "UTF-8");
                } catch (IOException e) {
                    System.out.println("Caught IOException when reading " + fileName + ".txt");
                }
            } catch(FileNotFoundException e) {
                System.out.println("Caught IOException when reading " + fileName + ".txt");
            }
        }
        else {
            BufferedWriter writer;
            try {
                writer = new BufferedWriter(new FileWriter(file));
                try {
                    writer.write(defaultData);
                    writer.close();
                    return defaultData;
                }
                catch(IOException e) {
                    System.out.println("Caught IOException when writing " + fileName + ".txt");
                }
            }
            catch(IOException e) {
                System.out.println("Caught IOException when writing " + fileName + ".txt");
            }
        }
        return null;
    }

    public static String[] getLinesArrayFromData(String input) {
        int count = 0;
        String unprocessed = input;
        for (int i=0;i<unprocessed.length();i++) {
            if (unprocessed.charAt(i) == '\n') {
                count++;
            }
        }
        ArrayList<String> data = new ArrayList<String>();
        if (unprocessed.length()>0) {
            for (int i=0;i<count;i++) {
                String line = (unprocessed.substring(0,unprocessed.indexOf('\n'))).trim();
                if ((line.trim()).length() > 0 && line.charAt(0) != '#') {
                    data.add(line.trim());
                }
                unprocessed = unprocessed.substring(unprocessed.indexOf('\n')+1);
            }
        }
        if ((unprocessed.trim()).length()>0 && unprocessed.charAt(0)!='#') {
            data.add(unprocessed.trim());
        }
        return data.toArray(new String[data.size()]);
    }
}


