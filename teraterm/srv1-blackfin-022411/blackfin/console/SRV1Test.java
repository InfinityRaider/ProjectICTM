/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *  SRV1Test.java - TCP/UDP test console for SRV-1 robot
 *    Copyright (C) 2005-2009  Surveyor Corporation
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details (www.gnu.org/licenses)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

import java.io.*;
import java.util.*;
import java.net.*;
import java.awt.*;
import java.awt.event.*;

public class SRV1Test
{
	private static String SRV_HOST = "192.168.0.15";
	private static int SRV_PORT = 10001;
	private static String SRV_PROTOCOL = "TDP"; // "UDP" or "TCP"
	private static int UDP_LOCAL_PORT = 10001; // the SRV-1 must be set to use this as its "Remote Port"

	private static String ARCHIVE_PREFIX = "srv";

	private static final int SO_TIMEOUT = 500;  // socket timeout (ms)
	private static final int MTU = 2048; // must be >= SRV-1 WiPort MTU (which has a default of 1400)

	private static PrintStream log = System.out;
	private static NetworkSRV1Reader srv1;

	private static Frame f;

	public static final String CMD_DELIM = ",";  // used to send multiple commands in one shot
	public static final String ENC_ASCII = "ASCII";
	public static final String ENC_HEX = "Hex";

	public static void main(String[] cmdLine) {
		Map args = parseCommandLine(cmdLine);
		if (args.containsKey("usage") || args.containsKey("help")) { 
			System.out.println("Command Line Options:");
			System.out.println("  -remote_addr : SRV-1 IP Address");
		    System.out.println("  -remote_port : SRV-1 Port");
            System.out.println("  -protocol    : TCP or UDP");
            System.out.println("  -local_port  : Local port (applicable to UDP only)");
            System.out.println("  -archive     : Archive directory where JPEG frames will be saved");
            return;
        }
        if (args.containsKey("remote_addr"))    SRV_HOST = (String) args.get("remote_addr");
        if (args.containsKey("remote_port")) SRV_PORT = toInt((String) args.get("remote_port"), 10001);
        if (args.containsKey("protocol")) SRV_PROTOCOL = ((String) args.get("protocol")).toUpperCase();
        if (args.containsKey("local_port")) UDP_LOCAL_PORT = toInt((String) args.get("local_port"), 10001);

        Canvas jpegRender = new JpegRenderer();
        jpegRender.setSize(320, 240);

        f = new Frame("SRV-1 Console - TCP/UDP");
        f.setBackground(Color.WHITE);
        f.setLayout(new BorderLayout(3, 3));
        f.add("Center", jpegRender);
        f.add("South", createBasicCommandPanel());
        f.pack();
        f.setVisible(true);
        f.repaint();
        // handle window close
        f.addWindowListener (new WindowAdapter() {
                public void windowClosing (WindowEvent evt) {
                    System.exit(0);
                }
            });

        java.util.List<FrameListener> frameListeners = new ArrayList<FrameListener>();
        frameListeners.add((FrameListener) jpegRender);
        if (args.containsKey("archive")) {  
            frameListeners.add(new SimpleFrameArchiver((String) args.get("archive")));
        }

        srv1 = new NetworkSRV1Reader(SRV_HOST, SRV_PORT, SRV_PROTOCOL, frameListeners);
        srv1.start();
    }

    private static Map<String,Object> parseCommandLine(String[] cmdLine)
    {
        Map<String,Object> args = new HashMap<String,Object>();
        int count = cmdLine.length;
        for (int i = 0; i < count; i++) {
            if (cmdLine[i].startsWith("-")) {
                // if next arg. starts with dash, use "true" as the value, otherwise
                // use the string value that follows this arg.
                if (i+1 >= count || cmdLine[i+1].startsWith("-"))
                    args.put(cmdLine[i].substring(1), Boolean.TRUE);
                else if (i+1 < count)
                    args.put(cmdLine[i].substring(1), cmdLine[++i]);
            }
        }
        return args;
    }

    private static int toInt(String s, int deflt)
    {
        int i = deflt;
        try { i = Integer.parseInt(s); }
        catch (Exception e) { i = deflt; }
        return i;
    }

    // Create a GUI panel that offers basic support for sending of SRV-1 commands 
    // and response display.
    private static Component createBasicCommandPanel()
    {
        final Choice encoding = new Choice();
        encoding.add(ENC_ASCII);
        encoding.add(ENC_HEX);

        final TextField commandField = new TextField(20);
        final Button sendButton = new Button("Send");
        final TextArea commandLog = new TextArea("", 5, 10);

        final ActionListener sendCommandAction = new ActionListener() {
                public void actionPerformed(ActionEvent e) {
                    String c = commandField.getText();
                    String[] commands = c.split(CMD_DELIM); 
                    
                    for (int i = 0; i < commands.length; i++) {
                        String cmdString = commands[i].trim();
                        byte[] cmdBytes = buildCommand(cmdString, encoding.getSelectedItem());
                        SRV1CommandCallback cb = new SRV1CommandCallback() {
                                public void success(String cmdString, String response) { 
                                    commandLog.append("[" + cmdString + "] " + 
                                                      response + System.getProperty("line.separator"));
                                    try {
                                        commandLog.setCaretPosition(Integer.MAX_VALUE);
                                    } catch (IllegalComponentStateException ise) { }
                                }
                                public void failure(String cmdString) { }
                            };

                        srv1.sendCommand(cmdString, cmdBytes, cb);
                    }
                }
            };

        sendButton.addActionListener(sendCommandAction);

        commandField.addKeyListener(new KeyListener() {
                public void keyTyped(KeyEvent e) { }
                public void keyPressed(KeyEvent e) { }
                public void keyReleased(KeyEvent e) { 
                    // on enter key, simulate "Send" button click
                    if (e.getKeyCode() == KeyEvent.VK_ENTER) {
                        sendCommandAction.actionPerformed(null); // FIXME: provide an ActionEvent?
                    }
                }
            });

        // encoding drop-down, command field & Send button on one line
        Panel pCmdLine = new Panel();
        pCmdLine.add(encoding);
        pCmdLine.add(commandField);
        pCmdLine.add(sendButton);

        Panel p = new Panel(new BorderLayout());
        p.add("North", pCmdLine);
        p.add("Center", commandLog);
        return p;
    }

    private static byte[] buildCommand(String text, String encoding)
    {
        try {
            if (ENC_HEX.equalsIgnoreCase(encoding)) {
                return (new java.math.BigInteger(text, 16)).toByteArray();
            } else {
                return text.getBytes("US-ASCII");
            }
        } catch (Exception e) {
            return null;
        }
    }

    private interface SRV1CommandCallback
    {
        public void success(String cmdString, String response);
        public void failure(String cmdString);
    }

    private static class SRV1Command
    {
        private final String cmdString;
        private final byte[] cmdBytes;
        private final SRV1CommandCallback callback;

        public SRV1Command(String cmdString, byte[] cmdBytes, SRV1CommandCallback callback) {
            this.cmdString = cmdString;
            this.cmdBytes = cmdBytes;
            this.callback = callback;
        }

        public String getString() { return this.cmdString; }
        public byte[] getBytes() { return this.cmdBytes; }
        public SRV1CommandCallback getCallback() { return this.callback; }
    }


    private interface FrameListener
    {
        public void newFrame(byte[] frame);
    }

    /**
     * Frame listener that stores each frame as a separate (timestamped) JPEG file in 
     * the specified 'archiveDirectory'.
     */
    private static class SimpleFrameArchiver extends Thread implements FrameListener
    {
        private String archiveDirectory;
        private byte[] buf = null;

        public SimpleFrameArchiver(String archiveDirectory) {
            this.archiveDirectory = archiveDirectory.endsWith(File.separator) ? 
                archiveDirectory : archiveDirectory + File.separator;
            File f = new File(this.archiveDirectory);
            if (f.exists() && !f.isDirectory()) {
                throw new IllegalArgumentException("'archiveDirectory' exists as a regular file");
            } else if (!f.exists()) {
                f.mkdir();
            }
            
            start();
        }

        public void run()
        {
            while (true) {
                if (buf == null) {
                    try { Thread.sleep(10); } catch (InterruptedException ie) { }
                    continue;
                }
                long tstamp = System.currentTimeMillis();
                FileOutputStream fos = null;
                try {
                    fos = new FileOutputStream(this.archiveDirectory + 
                                               ARCHIVE_PREFIX + tstamp + ".jpeg");
                    fos.write(buf);
                    buf = null;
                    fos.flush();
                } catch (Exception e) {
                    
                } finally {
                    try { fos.close(); } catch (Exception e) { }
                }
            }
        }
        public void newFrame(byte[] frame) {
            if (buf != null) return;  // drop frames if we fall behind
            buf = new byte[frame.length];
            System.arraycopy(frame, 0, buf, 0, frame.length);
        }
    }

    /**
     * Frame listener that decodes and renders JPEG frames to an AWT canvas.
     */
    private static class JpegRenderer extends Canvas implements FrameListener
    {
        private byte[] imgBuf = null;
        private Image img = null;
        private MediaTracker tracker = null;
        private int w, h, x, y;

        public JpegRenderer() {
            tracker = new MediaTracker(this);
        }

        public void paint(Graphics g) {
            if (img == null && imgBuf != null) {
                // hardly the most optimal way to decode a JPEG, but...
                img = Toolkit.getDefaultToolkit().createImage(imgBuf);
                tracker.addImage(img, 0);
                try {
                    tracker.waitForID(0);
                } catch (InterruptedException ie) {
                    log.println("JPEG decode error " + ie);
                }
                if (!tracker.isErrorID(0)) { }
                tracker.removeImage(img);
            }

            if (img != null) {
                // resize frame/window, if necessary
                if (w != img.getWidth(this) || h != img.getHeight(this)) {
                    w = img.getWidth(this);
                    h = img.getHeight(this);
                    if (w <= 25) {
                        w = 320;
                    }
                    if (h <= 25) {
                        h = 240; 
                    }
                    this.setSize(w, h);
                    f.pack();
                }

                // keep image centered, no matter the window size
                x = Math.max((this.getWidth() - w) / 2, 0);
                y = Math.max((this.getHeight() - h) / 2, 0);
                g.drawImage(img, x, y, null);
            }
        }

        public void update(Graphics g) {
            paint(g);
        }

        public void newFrame(byte[] frame) {
            imgBuf = new byte[frame.length];
            System.arraycopy(frame, 0, imgBuf, 0, frame.length);
            if (img != null) img.flush();
            img = null;
            repaint();
        }
    }

    private static final byte[] FRAME_HEAD = { '#', '#', 'I', 'M', 'J' };

    private static class NetworkSRV1Reader extends Thread
    {
        private InetAddress host;  // SRV-1 connection information
        private int port;
        private String transport;

        private Socket s = null;
        private DatagramSocket dgs = null;
        private InputStream is = null;  // only applicable in TCP mode
        private OutputStream os = null; // "
        private boolean udp = false; // true => UDP, false => TCP
        private boolean connected = false;

        private boolean shouldRun = true;

        private DatagramPacket frameRequest = null;

        private java.util.List<FrameListener> frameListeners = new ArrayList<FrameListener>();

        private java.util.List<SRV1Command> commandQueue = new ArrayList<SRV1Command>();

        public NetworkSRV1Reader(String host, int port, String transport, 
                                 java.util.List<FrameListener> frameListeners)
        {
            try { this.host = InetAddress.getByName(host); } 
            catch (Exception e) { throw new RuntimeException(e); }
            this.port = port;
            this.transport = transport;
            this.frameListeners = frameListeners;
            frameRequest = new DatagramPacket(new byte[] { (byte) 'I' }, 1, this.host, this.port);
            log.println("[NetworkSRV1Reader] - " + host + ":" + port + " (" + transport + ")");
        }

        public boolean sendCommand(String cmdString, byte[] cmdBytes, SRV1CommandCallback cb)
        {
            commandQueue.add(new SRV1Command(cmdString, cmdBytes, cb));
            return true;
        }

        public void interrupt()
        {
            this.shouldRun = false;
        }

        public void run()
        {
            byte[] frame = null;
            int framePos = 0; // current position in "frame" byte[]
            int frameCount = 0;
            long start = System.currentTimeMillis();

            while (this.shouldRun) {
                // 1) Send pending commands (if any), read responses
                // 2) Send frame request
                // 3) Read frame data
                // 4) goto step 1

                if (!connected) open();

                try {
                    if (frame == null) {

                        // run through the command queue befure requesting a new frame
                        while (!commandQueue.isEmpty()) {
                            SRV1Command c = (SRV1Command) commandQueue.remove(0);
                            _send(c.getBytes());
                            byte[] cmdResponse = new byte[MTU];
                            int resLen = _read(cmdResponse);
                            String response = "--no response--";
                            if (resLen > 0) { response = new String(cmdResponse, 0, resLen); }
                            c.getCallback().success(c.getString(), response);
                        }

                        _send(frameRequest);
                    }

                    byte[] buf = new byte[MTU];

                    int retries = 4;
                    int bytes = _read(buf);
                    while (retries-- > 0 && bytes < 0) {
                        bytes = _read(buf);
                    }

                    if (retries <= 0) {
                        frame = null;
                        framePos = 0;
                        continue;
                    }

                    if (bytes > 0 && frame == null) {
                        int frameStart = indexOf(buf, FRAME_HEAD, 0);
                        if (frameStart == -1) {
                            // TODO: read / discard everything on the line
                            continue;
                        } else {
                            int offset = FRAME_HEAD.length;
                            long frameSize = 0;
                            byte frameDim = buf[offset++];
                            log.println("frame dim: " + frameDim);
                            for (int i = 0; i < 4; i++) {
                                frameSize += (0xff & buf[offset++]) << (8 * i);
                            }
                            
                            log.println("frame size: " + frameSize);

                            frame = new byte[(int) frameSize];
                            framePos = 0;
                            System.arraycopy(buf, offset, frame, framePos, bytes - offset);
                            framePos += bytes - offset;
                        }
                    } else if (bytes > 0 && frame != null) {
                        int leftToRead = frame.length - framePos; // bytes that remain to be read

                        if (bytes < leftToRead) {
                            System.arraycopy(buf, 0, frame, framePos, bytes);
                            framePos += bytes;
                        } else {
                            System.arraycopy(buf, 0, frame, framePos, leftToRead);

                            // ship this frame out to the frame listener(s)
                            for (Iterator fl = this.frameListeners.iterator(); fl.hasNext(); ) {
                                ((FrameListener) fl.next()).newFrame(frame);
                            }

                            frameCount++;
                            long elapsed = (System.currentTimeMillis() - start) / 1000; // s
                            float fps = frameCount / (elapsed + 1);
                            log.println("read full frame, size: " + frame.length + ", " + fps + " fps");
                            framePos = 0;
                            frame = null;
                        }
                    } else {
                        // no bytes ready, delay
                        try { Thread.sleep(10); } catch (InterruptedException ie) { }
                    }

                } catch (Throwable t) {
                    log.println("[NetworkSRV1Reader] - error in main loop - " + t);
                    t.printStackTrace();
                }
            }

            close();
        }

        // Search for the sequence "part" in the full array "data", starting at index "start".
        // Returns -1 if the "data" array does not contain "part".
        private int indexOf(byte[] data, byte[] part, int start)
        {
            int match = -1;
            for (int i = start; i <= data.length - part.length && match == -1; i++)    {
                for (int j = 0; j < part.length && data[i + j] == part[j]; j++)    {
                    if (j == part.length - 1) {
                        match = i;
                    }
                }  
            }
            return match;
        }


        private int _read(byte[] buf) throws Exception
        {
            int bytes = -1;
            if (udp) {
                DatagramPacket dp = new DatagramPacket(buf, buf.length);
                try {
                    dgs.receive(dp);
                    bytes = dp.getLength();
                } catch (SocketTimeoutException ste) {
                    bytes = -1;
                }
            } else {
                try {
                    bytes = is.read(buf);
                } catch (SocketTimeoutException ste) {
                    bytes = -1;
                }

            }
            //log.println("_read() - " + bytes + " bytes");
            return bytes;
        }

        private void _send(DatagramPacket dp) throws Exception
        {
            if (udp) {
                dgs.send(dp);
            } else {
                os.write(dp.getData());
                os.flush();
            }
            //log.println("_send(DP) - " + dp.getData().length + " bytes");
        }

        private void _send(byte[] msg) throws Exception
        {
            if (udp) {
                DatagramPacket dp = new DatagramPacket(msg, msg.length,
                                                       this.host, this.port);
                dgs.send(dp);
            } else {
                os.write(msg);
                os.flush();
            }
            //log.println("_send() - " + msg.length + " bytes");
        }

        private boolean open()
        {
            if (connected) log.println("[NetworkSRV1Reader] - open() called when already connected");

            if ("UDP".equalsIgnoreCase(transport)) {
                // set up UDP socket
                try {
                    this.dgs = new DatagramSocket(UDP_LOCAL_PORT);
                    this.dgs.setSoTimeout(SO_TIMEOUT);
                    this.dgs.connect(this.host, this.port);
                    log.println("[NetworkSRV1Reader] - listening on UDP port: " + UDP_LOCAL_PORT);
                    udp = true;
                    connected = true;

                    //_send(new byte[] { 'a' });

                    return true;
                } catch (Exception e) {
                    log.println("[NetworkSRV1Reader] - error during UDP open() " + e);
                    e.printStackTrace();
                }
            } else {
                // default to TCP-mode
                try {
                    this.s = new Socket(host, port);
                    this.s.setSoTimeout(SO_TIMEOUT);
                    this.is = new BufferedInputStream(this.s.getInputStream());
                    this.os = new BufferedOutputStream(this.s.getOutputStream());
                    log.println("[NetworkSRV1Reader] - created TCP connection");
                    connected = true;
                    return true;
                } catch (Exception e) {
                    log.println("[NetworkSRV1Reader] - error during TCP open() " + e);
                    e.printStackTrace();
                }

            }
            close(); // clean up (possibly partially established connections)
            return false;
        }

        private boolean close()
        {
            if (this.dgs != null) try { this.dgs.close(); } catch (Exception e) { }
            if (this.is != null) try { this.is.close(); } catch (Exception e) { }
            if (this.os != null) try { this.os.close(); } catch (Exception e) { }
            if (this.s != null) try { this.s.close(); } catch (Exception e) { }
            this.s = null; this.dgs = null; this.is = null; this.os = null;
            connected = false;
            return true;
        }

    }

}
