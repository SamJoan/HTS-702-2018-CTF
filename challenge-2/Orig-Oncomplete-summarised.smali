# virtual methods
.method public onComplete(Ljava/lang/String;)V
    .locals 3
	[...]
    .line 32
    # Derive key from user input.
    iget-object v0, p0, Lcom/hackerone/mobile/challenge2/MainActivity$1;->this$0:Lcom/hackerone/mobile/challenge2/MainActivity;
    invoke-virtual {v0, p1}, Lcom/hackerone/mobile/challenge2/MainActivity;->getKey(Ljava/lang/String;)[B
    move-result-object p1
	[...]
    .line 37
    # init SecretBox With derived key.
    new-instance v0, Lorg/libsodium/jni/crypto/SecretBox;
    invoke-direct {v0, p1}, Lorg/libsodium/jni/crypto/SecretBox;-><init>([B)V

	# get bytes for static initialization vector.
    const-string p1, "aabbccddeeffgghhaabbccdd"
    invoke-virtual {p1}, Ljava/lang/String;->getBytes()[B
    move-result-object p1

    .line 42
    :try_start_0
    # Decrypt, failure will go to exception
    invoke-virtual {v0, p1, p0}, Lorg/libsodium/jni/crypto/SecretBox;->decrypt([B[B)[B
    move-result-object p0
	[...]
    const-string p0, "DECRYPTED"
    
	[...]
    const-string p1, "PROBLEM"
	const-string v0, "Unable to decrypt text"
    [...]
.end method
