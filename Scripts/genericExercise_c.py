import sys
import os

def main():
    argc = len(sys.argv)
    if (argc != 2):
        print("No more than 1 arg is needed")
        return 1
    folderName = sys.argv[1]
    os.mkdir(folderName)
    f = open(folderName + "/" + folderName + ".c" , "w")
    f.write("#include \"" + folderName + ".h\"\n\n")
    f.close()
    f = open(folderName + "/" + folderName + ".h" , "a")
    headerName = folderName.upper() + "_H"
    f.write("#ifndef " + headerName)
    f.write("\n#define " + headerName)
    f.write("\n\n// Content of " + headerName + "\n\n")
    f.write("#endif /* ! " + headerName + " */\n")
    f.close()
    return

main()
