@echo off 
c: 
if exist *.o del /q *.o 
if exist *.bin del /q *.bin 
if exist *.ldr del /q *.ldr 

mingw32-make.exe
if exist *.o del /q *.o 
if exist *.bin del /q *.bin 
if not exist "srv1.ldr" goto exit 
copy "srv1.ldr" "C:\SRV"

"c:\SRV\Teraterm\ttpmacro.exe" "c:\SRV\blackfin\srv\flash.ttl" 
 
:exit 
echo "exit"
pause 