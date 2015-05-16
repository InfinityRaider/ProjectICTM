package com.groupC1.control.network;

import com.groupC1.control.reference.Settings;
import org.apache.commons.net.telnet.*;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class TelnetHandler implements Runnable, TelnetNotificationHandler{
    private TelnetClient client;
    private String ip;
    private int port;

    private boolean connected = false;
    private OutputStream outputStream;
    private InputStream inputStream;

    public TelnetHandler(String ip, int port) {
        this.ip = ip;
        this.port = port;
        client = new org.apache.commons.net.telnet.TelnetClient();
        TerminalTypeOptionHandler ttopt = new TerminalTypeOptionHandler("VT100", false, false, true, false);
        EchoOptionHandler echoopt = new EchoOptionHandler(true, false, true, false);
        SuppressGAOptionHandler gaopt = new SuppressGAOptionHandler(true, true, true, true);
        try {
            client.addOptionHandler(ttopt);
            client.addOptionHandler(echoopt);
            client.addOptionHandler(gaopt);
        }
        catch (Exception e) {
            System.err.println("Error registering option handlers: " + e.getMessage());
        }
    }

    public void sendMessage(char message) {sendMessage((byte) message);}

    public void sendMessage(byte message) {
        byte[] array = new byte[] {message};
        sendMessage(array);
    }

    public void sendMessage(byte[] message) {
        boolean wasConnected = isConnected();
        if(!wasConnected) {
            connect();
        }
        try {
            outputStream.write(message);
            outputStream.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
        if(!wasConnected) {
            disconnect();
        }
    }

    public boolean isConnected() {
        return connected;
    }

    public void connect() {
        if(!isConnected()) {
            try {
                client.connect(ip, port);
            } catch (IOException e) {
                e.printStackTrace();
            }
            Thread reader = new Thread(this);
            client.registerNotifHandler(this);
            try {
                if (!client.sendAYT(Settings.TIMEOUT_WAIT_TIME)) {
                    throw new TimeOutException();
                }
                else {
                    System.out.println("AYT Received");
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            reader.start();
            outputStream = client.getOutputStream();
            inputStream = client.getInputStream();
            connected = true;
        }
    }

    public void disconnect(){
        if(isConnected()) {
            try {
                client.disconnect();
            } catch (IOException e) {
                e.printStackTrace();
            }
            connected = false;
            outputStream = null;
            inputStream = null;
        }
    }

    @Override
    public void run() {
        while(inputStream!=null) {
            try {
                byte[] buff = new byte[1024];
                int ret_read = inputStream.read(buff);
                while (ret_read >= 0) {
                    if (ret_read > 0) {
                        System.out.print(new String(buff, 0, ret_read));
                    }
                    ret_read = inputStream.read(buff);
                }
            } catch (IOException e) {
                System.err.println("Exception while reading socket:" + e.getMessage());
            }
        }
    }

    @Override
    public void receivedNegotiation(int negotiation_code, int option_code) {}

    private static class TimeOutException extends Exception {
        public TimeOutException() {
            super("Connection timed out");
        }
    }
}
