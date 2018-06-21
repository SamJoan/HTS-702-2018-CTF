# virtual methods
.method public onComplete(Ljava/lang/String;)V
    .locals 3

    .line 32
    iget-object v0, p0, Lcom/hackerone/mobile/challenge2/MainActivity$1;->this$0:Lcom/hackerone/mobile/challenge2/MainActivity;

    iget-object v0, v0, Lcom/hackerone/mobile/challenge2/MainActivity;->TAG:Ljava/lang/String;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "Pin complete: "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 34
    iget-object v0, p0, Lcom/hackerone/mobile/challenge2/MainActivity$1;->this$0:Lcom/hackerone/mobile/challenge2/MainActivity;

    invoke-virtual {v0, p1}, Lcom/hackerone/mobile/challenge2/MainActivity;->getKey(Ljava/lang/String;)[B

    move-result-object p1

    const-string v0, "TEST"

    .line 35
    invoke-static {p1}, Lcom/hackerone/mobile/challenge2/MainActivity;->bytesToHex([B)Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 37
    new-instance v0, Lorg/libsodium/jni/crypto/SecretBox;

    invoke-direct {v0, p1}, Lorg/libsodium/jni/crypto/SecretBox;-><init>([B)V

    const-string p1, "aabbccddeeffgghhaabbccdd"

    .line 39
    invoke-virtual {p1}, Ljava/lang/String;->getBytes()[B

    move-result-object p1

    .line 42
    :try_start_0
    iget-object p0, p0, Lcom/hackerone/mobile/challenge2/MainActivity$1;->this$0:Lcom/hackerone/mobile/challenge2/MainActivity;

    invoke-static {p0}, Lcom/hackerone/mobile/challenge2/MainActivity;->access$000(Lcom/hackerone/mobile/challenge2/MainActivity;)[B

    move-result-object p0

    invoke-virtual {v0, p1, p0}, Lorg/libsodium/jni/crypto/SecretBox;->decrypt([B[B)[B

    move-result-object p0

    .line 44
    new-instance p1, Ljava/lang/String;

    sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {p1, p0, v0}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    const-string p0, "DECRYPTED"

    .line 46
    invoke-static {p0, p1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception p0

    const-string p1, "PROBLEM"

    const-string v0, "Unable to decrypt text"

    .line 48
    invoke-static {p1, v0}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 49
    invoke-virtual {p0}, Ljava/lang/RuntimeException;->printStackTrace()V

    :goto_0
    return-void
.end method
