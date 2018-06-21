public class MainActivity extends AppCompatActivity
{

    private byte[] cipherText;
[...]
    static {
        System.loadLibrary("native-lib");
[...]
            public void onComplete(final String s) {
                final String tag = MainActivity.this.TAG;
                final StringBuilder sb = new StringBuilder();
                sb.append("Pin complete: ");
                sb.append(s);
                Log.d(tag, sb.toString());
                final byte[] key = MainActivity.this.getKey(s);
                Log.d("TEST", MainActivity.bytesToHex(key));
                final SecretBox secretBox = new SecretBox(key);
                final byte[] bytes = "aabbccddeeffgghhaabbccdd".getBytes();
                try {
                    Log.d("DECRYPTED", new String(secretBox.decrypt(bytes, MainActivity.this.cipherText), StandardCharsets.UTF_8));
                }
                catch (RuntimeException ex) {
                    Log.d("PROBLEM", "Unable to decrypt text");
                    ex.printStackTrace();
                }
            }
 [...]
    public native byte[] getKey(final String p0);
    public native void resetCoolDown();
    
    @Override
    protected void onCreate(final Bundle bundle) {
[...]
        this.cipherText = new Hex().decode("9646D13EC8F8617D1CEA1CF4334940824C700ADF6A7A3236163CA2C9604B9BE4BDE770AD698C02070F571A0B612BBD3572D81F99");
[...]
    }
}
