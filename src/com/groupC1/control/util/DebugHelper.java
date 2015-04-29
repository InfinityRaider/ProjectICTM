package com.groupC1.control.util;

import com.groupC1.control.reference.Settings;

public class DebugHelper {
    public static void debug(String data) {
        if(Settings.DEBUG_MODE) {
            System.out.println(data);
        }
    }
}
