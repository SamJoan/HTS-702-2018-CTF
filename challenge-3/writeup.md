## Challenge 3

Welcome back to the third round of mobile challenges. When we start up the third mobile challenge, we're welcomed by the following message:

```
We could not find the original apk, but we got this. Can you make sense of it?

challenge3_release.zip
```

This was a bit of a shock to me because I was all ready to start with the usual apktool combo, and was really expecting something in the vein of the previous challenges. Let's open up the `.zip` file and see whats in it:

```
$ unzip challenge3_release.zip 
Archive:  challenge3_release.zip
  inflating: boot.oat
  inflating: base.odex
```
At this point, I have no idea what these files are. Running `file` on them, I get output indicative of them being `.so` files, which we clearly know is not the case.  Because I am lazy, I tried extracting the files with the `binwalk` tool, which is my go-to tool when dealing with unknown file types. Binwalk in this case gets stuck in a loop and does not extract any meaningful files.

After doing some cursory reading on the file extensions, it seems that an `.odex` file is a pre-processed version of an Android file. If we rooted a device, for example, and wanted to perform modifications on some proprietary version of some pre-installed app, we would have to deal with `.odex` files, as well as accompanying `.oat` files. The process of converting them back to something workable seems to be called "deodexing", which we can do with the `baksmali` tool.

This tool can be installed by downloading a `.jar` file and then executing `java -jar` on it. While you're downloading `baksmali` make sure you get the `smali` jar too because we are going to use it. Because I am not familiar with the processes that are involved, I look up some tutorials online but it seems that the syntax has changed as of release 2.2. Inferring the new syntax from the old commands, I do the following:

```
$ java -jar ../../baksmali-2.2.4.jar deodex boot.oat
$ java -jar ../../baksmali-2.2.4.jar deodex base.odex
org.jf.dexlib2.analysis.AnalysisException: Could not resolve the method in class Landroid/support/v7/widget/MenuPopupWindow$MenuDropDownListView; at index 1053
        at org.jf.dexlib2.analysis.MethodAnalyzer.analyzeInvokeVirtualQuick(MethodAnalyzer.java:1824)
        at org.jf.dexlib2.analysis.MethodAnalyzer.analyzeInstruction(MethodAnalyzer.java:1040)
        [...]
        
```
As you can see, the process crashed while deodexing some built-in class. While I have no idea how to resolve this, a new folder called `out/` was created which hopefully contains the important bits.

```
$ ls out/
android  com  java  javax  sun
$ ls out/com/hackerone/mobile/challenge3/MainActivity*
out/com/hackerone/mobile/challenge3/MainActivity$1.smali
out/com/hackerone/mobile/challenge3/MainActivity.smali
```

I have a look at the smali code and I can readily see there's some nonsense going on. String concatenation, decodings, encodings and typical time-wasting security by obscurity. I run a few quick google searches on my hopes of converting this application into something that will run on my device and it seems futile. Considering there does not seem to be any real security measures, I think that decoding the code to Java hopefully gives me enough information to resolve the challenge.

We are going to do so by converting the out folder back into a dex file, converting the `dex` file into a `jar` file and then running procyon as before.

```
$ java -jar ../../smali-2.2.4.jar ass out/
$ ../../dex-tools-2.1-20171001-lanchon/d2j-dex2jar.sh out.dex 
dex2jar out.dex -> ./out-dex2jar.jar
[...]
$ java -jar ~/decompiler.jar out-dex2jar.jar -o src
Decompiling java/lang/Object...
Decompiling android/arch/core/BuildConfig...
[...]
```

Now, as I suspected, the code looks like I described above:

```
final String encryptDecrypt = encryptDecrypt(MainActivity.key, hexStringToByteArray(new StringBuilder("kO13t41Oc1b2z4F5F1b2BO33c2d1c61OzOdOtO").reverse().toString().replace("O", "0").replace("t", "7").replace("B", "8").replace("z", "a").replace("F", "f").replace("k", "e")));
        return s.length() <= s.length() || s.substring("flag{".length(), s.length() - 1).equals(encryptDecrypt);
```

I am no computer and I am not going to waste time trying to pretend to be a computer. I am going to grab that code, jam it into a Java class and going to get the output. My final Java class looks like this:

```
public class MainActivity {
    private static char[] key;
    
    static {
        MainActivity.key = new char[] { 't', 'h', 'i', 's', '_', 'i', 's', '_', 'a', '_', 'k', '3', 'y' };
    }
    
    public static void main(String[] args) {
        final String encryptDecrypt = encryptDecrypt(MainActivity.key, hexStringToByteArray(new StringBuilder("kO13t41Oc1b2z4F5F1b2BO33c2d1c61OzOdOtO").reverse().toString().replace("O", "0").replace("t", "7").replace("B", "8").replace("z", "a").replace("F", "f").replace("k", "e")));                                                                                                                                               
        System.out.println(encryptDecrypt);
    }
            
    public static boolean checkFlag(final String s) {
        if (s.length() == 0) {
            return false;
        }
        if (s.length() > "flag{".length() && !s.substring(0, "flag{".length()).equals("flag{")) {
            return false;
        }
        if (s.charAt(s.length() - 1) != '}') {
            return false;
        }
        final String encryptDecrypt = encryptDecrypt(MainActivity.key, hexStringToByteArray(new StringBuilder("kO13t41Oc1b2z4F5F1b2BO33c2d1c61OzOdOtO").reverse().toString().replace("O", "0").replace("t", "7").replace("B", "8").replace("z", "a").replace("F", "f").replace("k", "e")));                                                                                                                                               
        return s.length() <= s.length() || s.substring("flag{".length(), s.length() - 1).equals(encryptDecrypt);
    }
    
    private static String encryptDecrypt(final char[] array, final byte[] array2) {
        final StringBuilder sb = new StringBuilder();
        for (int i = 0; i < array2.length; ++i) {
            sb.append((char)(array2[i] ^ array[i % array.length]));
        }
        return sb.toString();
    }
    
    public static byte[] hexStringToByteArray(final String s) {
        final int length = s.length();
        final byte[] array = new byte[length / 2];
        for (int i = 0; i < length; i += 2) {
            array[i / 2] = (byte)((Character.digit(s.charAt(i), 16) << 4) + Character.digit(s.charAt(i + 1), 16));
        }
        return array;
    }
                                                                               
```

We can now run the code and get the key:

```
javac MainActivity.java && java MainActivity
secr3t_littl3_th4ng
```

Of course we know the flag format and we can infer the key is `flag{secr3t_littl3_th4ng}`. I type that in and, BAM! done:

![](/home/user/work/shared/flags/HTS-702-2018-CTF/challenge-3/done.png) 