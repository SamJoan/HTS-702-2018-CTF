## Challenge 4

And here's what I think will be my last writeup, given the time constraints and the possibility that I may never get the time to write up the fifth challenge, even if I did complete it within the timeframe which is not looking super likely.

Once again, after going to the corresponding page we are greeted with a zip file. Looking inside there's a presumably vulnerable application and another file, called `setup_instructions.md`. Because we don't want to be dealing with incompatibilities between devices nor playing around, we're going to follow these to the letter. They are as below:
```
# Create emulator
...
avdmanager create avd -n pwnable-emulator -k "system-images;android-28;default;x86_64"
...

# Run emulator
...
emulator -wipe-data -accel on -no-boot-anim -no-audio -avd pwnable-emulator
...

# Setup emulator
...
adb install <apk>
adb shell echo flag{this_is_the_flag} > /data/local/tmp/challenge4
adb shell su root chown root:<apk user> /data/local/tmp/challenge4
adb shell su root chmod 550 /data/local/tmp/challenge4
...

# Run apk
...
pkg=$(aapt dump badging <apk>|awk -F" " '/package/ {print $2}'|awk -F"'" '/name=/ {print $2}')
act=$(aapt dump badging <apk>|awk -F" " '/launchable-activity/ {print $2}'|awk -F"'" '/name=/ {print $2}')
adb shell am start -n "$pkg/$act"
...
```

It seems we need `avdmanager`, which comes with the linux sdk tools. There is a package for an ancient version on debian, but we need a relatively new version based on the system choice made in the instructions. You can download the SDK tools by going [here](https://developer.android.com/studio/#downloads) and installing Android Studio. The tools will be installed at `~/Android/Sdk/tools/bin/`. If they aren't, you can always download them manually and extract them in that location, although you may still need Android studio at some point.

You can then add them to your path by adding the following line to your `~/.bashrc` file:

```
export PATH=/home/user/Android/Sdk/tools/bin:$PATH
export PATH=/home/user/Android/Sdk/tools:$PATH
```

Let's create the VM:

```

$ avdmanager create avd -n pwnable-emulator -k "system-images;android-28;default;x86_64"
[...]
Do you wish to create a custom hardware profile? [no] n
```

Let's do a test run. We need to cd to the emulator's path due to [a bug in the tools](https://issuetracker.google.com/issues/37137213) a bug in the tools apparently. If you get regarding permissions you need to [fix some permissions](https://stackoverflow.com/questions/37300811/android-studio-dev-kvm-device-permission-denied) fix some permissions and restarting your PC.

```
$ cd ~/Android/Sdk/tools/
$ emulator -wipe-data -accel on -no-boot-anim -no-audio -avd pwnable-emulator
warning: host doesn't support requested feature: CPUID.80000001H:ECX.abm [bit 5]
warning: host doesn't support requested feature: CPUID.80000001H:ECX.abm [bit 5]
Your emulator is out of date, please update by launching Android Studio:
 - Start Android Studio
 - Select menu "Tools > Android > SDK Manager"
 - Click "SDK Tools" tab
 - Check "Android Emulator" checkbox
 - Click "OK"
```

Despite these errors we get a fine looking emulator:

![](/home/user/work/shared/flags/HTS-702-2018-CTF/challenge-4/Screenshot_2018-06-28_14-41-13.png) 

We can now install the vulnerable APK and create a fake flag, for testing. I created this script to automate the setup:

```
adb install challenge4_release.apk
userId=`adb shell dumpsys package com.hackerone.mobile.challenge4 | grep userId | awk -F= '{print $2}'`
adb shell "echo flag{this_is_the_flag} > /data/local/tmp/challenge4"
adb shell su root chown root:$userId /data/local/tmp/challenge4
adb shell su root chmod 550 /data/local/tmp/challenge4
adb shell ls -la /data/local/tmp/challenge4
pkg=$(aapt dump badging challenge4_release.apk|awk -F" " '/package/ {print $2}'|awk -F"'" '/name=/ {print $2}')
act=$(aapt dump badging challenge4_release.apk|awk -F" " '/launchable-activity/ {print $2}'|awk -F"'" '/name=/ {print $2}')
adb shell am start -n "$pkg/$act"
```

With all the setup out of the way, we can now open the application. What a pain! Let's run the script and see the output of the emulator:

```
$ chmod +x setup.sh 
$ ./setup.sh
```

![](/home/user/work/shared/flags/HTS-702-2018-CTF/challenge-4/Screenshot_2018-06-28_14-59-44.png) 

Sweet. Let's have a look at this thing, and see where the vulnerabilities are most likely to lie. Like on previous writeups for this CTF I will run the APK through `apktool` and `procyon` just to have better access to the app. These outputs will be in `challenge4_release` and `final-source` respectively. 

At this point, having had a brief look of the application, I can see that it is some sort of game. Frequently in vulnerable Android applications, the vulnerability lays within how it communicates with other applications within the device. Android provides several mechanisms through which applications may communicate between each other and handling input sent in that manner insecurely can frequently lead to vulnerabilities. Let's have a look at the vulnerable application's `AndroidManifest.xml`:

```
$ cat challenge4_release/AndroidManifest.xml 
<?xml version="1.0" encoding="utf-8" standalone="no"?><manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.hackerone.mobile.challenge4">
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <application android:allowBackup="true" android:icon="@mipmap/ic_launcher" android:label="@string/app_name" android:roundIcon="@mipmap/ic_launcher_round" android:supportsRtl="true" android:theme="@style/AppTheme">
        <activity android:name="com.hackerone.mobile.challenge4.MenuActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <activity android:name="com.hackerone.mobile.challenge4.MainActivity"/>
        <activity android:name="com.hackerone.mobile.challenge4.InfoActivity"/>
        <receiver android:name="com.hackerone.mobile.challenge4.MazeMover">
            <intent-filter>
                <action android:name="com.hackerone.mobile.challenge4.broadcast.MAZE_MOVER"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

As I suspected, there is a broadcast receiver, which is represented in the XML file above with a `<receiver>` tag. I am no expert on Android development but I know this is one of the mechanisms for inter-application communications so if there is a vulnerability that is likely to be where it is at. Let's look at the class referenced in that tag, MazeMover:

```
public class MazeMover
{
    public static void onReceive(final Context context, Intent intent) {
        if (MainActivity.getMazeView() == null) {
            Log.i("MazeMover", "Not currently trying to solve the maze");
            return;
        }   
        final GameManager gameManager = MainActivity.getMazeView().getGameManager();
        final Bundle extras = intent.getExtras();
        if (extras != null) {
            if (intent.hasExtra("get_maze")) {
            [...]
            }  else if (intent.hasExtra("move")) {
                final char char1 = extras.getChar("move");
                int n = -1;
             [...]
            } else if (intent.hasExtra("cereal")) {
                ((GameState)intent.getSerializableExtra("cereal")).initialize(context);
            }
[...]
```
I can see the vulnerability there right away. On the `cereal` extra, it will accept a serialized object which will be deserialized within the context of the vulnerable application. This opens up a [Java Deserialization Vulnerability](https://www.owasp.org/index.php/Deserialization_of_untrusted_data), which can lead to remote code execution depending on the classes that are available within the vulnerable application's classpath.

Alternatively, receivers can be registered using the `registerReceiver` method. I'll do a grep to see if there are any more receivers:

```
$ grep -nHR registerReceiver com -A 6
com/hackerone/mobile/challenge4/MainActivity.java:39:        this.registerReceiver((BroadcastReceiver)new BroadcastReceiver() {
com/hackerone/mobile/challenge4/MainActivity.java-40-            public void onReceive(final Context context, final Intent intent) {
com/hackerone/mobile/challenge4/MainActivity.java-41-                MazeMover.onReceive(context, intent);
com/hackerone/mobile/challenge4/MainActivity.java-42-            }
com/hackerone/mobile/challenge4/MainActivity.java-43-        }, new IntentFilter("com.hackerone.mobile.challenge4.broadcast.MAZE_MOVER"));
com/hackerone/mobile/challenge4/MainActivity.java-44-    }
com/hackerone/mobile/challenge4/MainActivity.java-45-
--
com/hackerone/mobile/challenge4/MenuActivity.java:66:        this.registerReceiver((BroadcastReceiver)new BroadcastReceiver() {
com/hackerone/mobile/challenge4/MenuActivity.java-67-            public void onReceive(final Context context, final Intent intent) {
com/hackerone/mobile/challenge4/MenuActivity.java-68-                if (intent.hasExtra("start_game")) {
com/hackerone/mobile/challenge4/MenuActivity.java-69-                    context.startActivity(new Intent(context, (Class)MainActivity.class));
com/hackerone/mobile/challenge4/MenuActivity.java-70-                }
com/hackerone/mobile/challenge4/MenuActivity.java-71-            }
com/hackerone/mobile/challenge4/MenuActivity.java-72-        }, new IntentFilter("com.hackerone.mobile.challenge4.menu"));
```
There are two new receivers, with a new menu receiver to navigate to the game and a duplicate receiver for `MAZE_MOVER.`

Before we can exploit the app we need to send simple messages to the application. Let's get started and open up Android Studio by extracting the zip it comes in and running the `android-studio/bin/studio.sh` file. Create a new project and choose an elite application name and package name like `com.leet.rekt.SuperXPloitSupreme`. For minSdkVersion choose `24` and then create a basic activity. This activity will have an `onCreate` method, which you can execute code that will run when the app starts. You can interact with background receivers with intents, like so:

```
Log.d("MYAPP", "Sending intent");
Intent testIntent = new Intent("com.hackerone.mobile.challenge4.menu");
testIntent.putExtra("start_game", true);
sendBroadcast(testIntent);
```

You can test this works if the application navigates to the start of the game. In my case it worked. Now we can test another basic intent works by calling get_maze. We first need to register a receiver to get the responses.
