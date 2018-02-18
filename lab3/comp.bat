masm %1.asm %1.obj ;;
link %1.obj ;;
exe2bin %1.exe %1.com
del %1.obj
del %1.exe